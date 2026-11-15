#!/bin/bash
# Collect kernel verification data into verify/.
#
# Data collection only: it is deliberately NOT set -e, because a partially built
# tree should still upload whatever evidence exists. Hard assertions live in the
# dedicated "Assert KernelSU integrated" workflow step.
#
# Inputs (env): OUT_DIR, KERNEL_NAME, KSU_VERSION_OVERRIDE, GITHUB_WORKSPACE
set -uo pipefail

out_dir="${OUT_DIR:-out}"
name="${KERNEL_NAME:?KERNEL_NAME is required}"
mkdir -p verify

echo "===== CONFIG_KSU* ====="
grep -E '^CONFIG_KSU' "$out_dir/.config" 2>/dev/null | sort | tee verify/ksu-config.txt

echo "===== KernelSU-Next metadata ====="
# drivers/kernelsu is a symlink to <vendored>/KernelSU-Next/kernel, so UPSTREAM has
# to be read from the vendored checkout itself, not through the kernel tree.
for upstream in \
    "${GITHUB_WORKSPACE:-.}/kernelsu/KernelSU-Next/UPSTREAM" \
    "$name/kernelsu/../UPSTREAM"
do
    if [ -f "$upstream" ]; then
        cp -f "$upstream" verify/ksu-next-commit.txt
        break
    fi
done
[ -f verify/ksu-next-commit.txt ] || echo "UPSTREAM not found" > verify/ksu-next-commit.txt
cat verify/ksu-next-commit.txt
echo "KSU_VERSION_OVERRIDE=${KSU_VERSION_OVERRIDE:-unset}" | tee -a verify/ksu-next-commit.txt

echo "===== susfs symbols ====="
grep -E 'susfs_|ksu_handle_sys_reboot' "$out_dir/System.map" 2>/dev/null \
    | sort -k3 | tee verify/susfs-symbols.txt

echo "===== dispatch constants in ksu_handle_sys_reboot ====="
objdump_bin="$(ls "${GITHUB_WORKSPACE:-.}"/clang-AOSP/bin/llvm-objdump 2>/dev/null || command -v llvm-objdump || true)"
if [ -n "$objdump_bin" ]; then
    "$objdump_bin" -d --no-show-raw-insn "$out_dir/vmlinux" 2>/dev/null \
        | awk '/<ksu_handle_sys_reboot>:/{f=1} f{print} f&&/^$/{exit}' \
        | grep -E '0x555(60|70|71|72|80)|0x60020' \
        | tee verify/dispatch-constants.txt
else
    echo "llvm-objdump not found" | tee verify/dispatch-constants.txt
fi

cp -f "$out_dir/System.map" verify/System.map 2>/dev/null || true
cp -f "$out_dir/.config" verify/config.txt 2>/dev/null || true
echo "verify artifacts ready"
