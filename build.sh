#!/bin/bash
#
# MoonWake local build script — mirrors the CI release configuration.
#
# Kept equivalent to .github/workflows/build.yml on purpose: same defconfig, same
# vendor fragments, same KCFLAGS, KernelSU injected before defconfig, and the
# AnyKernel3 tree taken from the vendored copy in this repository.
#
set -euo pipefail

SECONDS=0 # builtin bash timer
DEVICE="ruby"
ZIPNAME="MoonWake-Private-$(date '+%Y%m%d-%H%M').zip"

export ARCH=arm64
export KBUILD_BUILD_USER="${KBUILD_BUILD_USER:-rainyxeon}"
export KBUILD_BUILD_HOST="${KBUILD_BUILD_HOST:-private.deepinrain.com}"

TOOLCHAIN_BIN="${TOOLCHAIN_BIN:-/home/rainyxeon/toolchains/r563880/bin}"
if [ -d "$TOOLCHAIN_BIN" ]; then
	export PATH="$TOOLCHAIN_BIN:$PATH"
else
	echo "[MoonWake] toolchain not found at $TOOLCHAIN_BIN, using current PATH"
fi

# Keep these in sync with configs/release/compression-c2.json
DEFCONFIG="${DEFCONFIG:-ruby_defconfig}"
KSU_SETUP_ARG="${KSU_SETUP_ARG:-legacy-susfs-v2-susmount}"
EXTRA_CONFIGS="${EXTRA_CONFIGS:-vendor/bbr.config vendor/noop.config vendor/kernelsu.config vendor/susfs.config vendor/kernelpatch.config vendor/zram_compress.config vendor/hybridmount.config vendor/gaming_balanced.config vendor/compression.config vendor/logging-hm.config}"
AK3_DIR="${AK3_DIR:-$PWD/anykernel3}"
OUT="${OUT:-out}"
KERNEL_IMAGE="$OUT/arch/arm64/boot/Image.gz-dtb"

MAKE_ARGS=(
	-j"$(nproc)"
	"O=$OUT"
	ARCH=arm64
	LLVM=1
	LLVM_IAS=1
	CROSS_COMPILE=aarch64-linux-gnu-
	CROSS_COMPILE_ARM32=arm-linux-gnueabi-
	KCFLAGS="-O3 -march=armv8.2-a+crypto+fp16+dotprod -mcpu=cortex-a78 -mtune=cortex-a78"
)

if [[ "${1:-}" == "-c" || "${1:-}" == "--clean" ]]; then
	rm -rf "$OUT"
	echo "[MoonWake] cleaned $OUT"
fi

make_config() {
	echo "[MoonWake] configuring: $DEFCONFIG + vendor fragments"
	make "${MAKE_ARGS[@]}" "$DEFCONFIG"
	for fragment in $EXTRA_CONFIGS; do
		echo "[MoonWake]  + $fragment"
		make "${MAKE_ARGS[@]}" "$fragment"
	done
}

# drivers/Kconfig has no unconditional source line for kernelsu: the injection
# below is what makes CONFIG_KSU survive defconfig. Skipping it silently builds a
# kernel without root, so it runs before any config step.
echo "[MoonWake] injecting KernelSU-Next ($KSU_SETUP_ARG)"
sh ci/ksun-moonwake.sh "$KSU_SETUP_ARG"

if [[ "${1:-}" == "-mc" || "${1:-}" == "--makeconfig" || "${2:-}" == "-mc" || "${2:-}" == "--makeconfig" ]]; then
	make_config
elif [ ! -f "$OUT/.config" ]; then
	echo "[MoonWake] no $OUT/.config yet, configuring first"
	make_config
fi

grep -q '^CONFIG_KSU=y$' "$OUT/.config" || {
	echo "[MoonWake] CONFIG_KSU=y missing from $OUT/.config — drivers/kernelsu was not wired in" >&2
	exit 1
}

mkdir -p "$OUT"
echo "[MoonWake] building Image.gz-dtb for $DEVICE"
# Remove the stale image first so a failed build cannot be mistaken for a success.
rm -f "$KERNEL_IMAGE"
make "${MAKE_ARGS[@]}" Image.gz-dtb

if [ ! -f "$KERNEL_IMAGE" ]; then
	echo "[MoonWake] compilation failed: $KERNEL_IMAGE missing" >&2
	exit 1
fi

echo "[MoonWake] kernel built, packing AnyKernel3"

if [ -d "$AK3_DIR" ]; then
	cp -a "$AK3_DIR" AnyKernel3
	echo "[MoonWake] AnyKernel3 => vendored ($AK3_DIR)"
else
	git clone -q https://github.com/kernel-build-from-rainyland/AnyKernel3 -b ruby_private AnyKernel3 || {
		echo "[MoonWake] AnyKernel3 not vendored and clone failed" >&2
		exit 1
	}
	echo "[MoonWake] AnyKernel3 => cloned ruby_private"
fi

cp "$KERNEL_IMAGE" AnyKernel3/
(
	cd AnyKernel3
	zip -r9 "../$ZIPNAME" . -x '.git/*'
)
rm -rf AnyKernel3

echo "[MoonWake] completed in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s)"
echo "[MoonWake] zip: $ZIPNAME"
