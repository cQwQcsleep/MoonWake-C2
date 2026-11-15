# MoonWake C2 monorepo

Single repository for building MoonWake 2.7.0 C2 (Xiaomi `ruby`, MT6877, Linux 4.19.325).

- Kernel source: branch `c2`
- CI workflow: `.github/workflows/build.yml` (thin orchestration only)
- Release configs: `configs/release/compression-c2.json` … `compression-c2h.json`
- Vendored deps: `anykernel3/`, `kernelsu/KernelSU-Next/`

## Build

GitHub Actions → Build MoonWake Kernel → Run workflow:

- Batch: `config_type=release`, leave `config_file` blank. Builds every config in
  `configs/release/` that is **not** marked `"deprecated": true` (currently C2, C2A–C2F, C2H).
- Single variant: `config_type=release`, `config_file=compression-c2h.json`.
- `full_dump` / `send_to_telegram`: `false` unless you want the dump artifact / channel push.

Variants: C2A (base), C2B (GPU OC), C2C (CPU 2.8 GHz), C2D (GPU + CPU 2.8 GHz),
C2E (CPU 2.8/3.0 GHz), C2F (GPU + CPU 2.8/3.0 GHz), C2H (16-slot CPU OC with matching
MCUPM/PVT table).

**C2G is deprecated.** Its config is byte-identical to C2H apart from the name — the
18-step CPU table it was named after no longer exists in this tree, and it is known to
park the second cluster at the wrong frequency at idle. Batch mode skips it; requesting
`compression-c2g.json` explicitly still builds it, with a warning.

Outputs:

- `<kernel>_ak3.zip` per variant (AnyKernel3 payload).
- `verify-<kernel>-<run_number>`: `.config`, `System.map`, KSU metadata, susfs symbols,
  `ksu_handle_sys_reboot` dispatch constants.
- One GitHub Release per run, tagged `mwk-2.7.0-<run_number>`.

## Local build

```sh
sh ci/ksun-moonwake.sh --cleanup   # optional: undo a previous injection
./build.sh                         # ruby_defconfig + vendor fragments + KernelSU
./build.sh -c                      # clean build
```

`build.sh` mirrors the CI config on purpose: same defconfig, same `vendor/*.config`
fragments, same `KCFLAGS`, KernelSU injected **before** defconfig (without it Kconfig
silently drops `CONFIG_KSU`), stale `Image.gz-dtb` removed before the build, AnyKernel3
taken from the vendored `anykernel3/`. Overrides via env: `TOOLCHAIN_BIN`, `DEFCONFIG`,
`EXTRA_CONFIGS`, `KSU_SETUP_ARG`, `AK3_DIR`, `OUT`.

## ci/ scripts

| Script | Role |
|---|---|
| `gen-matrix.sh` | Build the matrix from configs; skips `"deprecated": true` in batch mode |
| `resolve-scripts.sh` | Map config `*_link` URLs to audited local copies in `ci/`; remote bytes must match |
| `toolchains.sh` | Fetch toolchains (repo or archive) with hard retry failure |
| `set-args.sh` | Assemble the `make` argument string |
| `ksun-moonwake.sh` | Inject KernelSU-Next into the kernel tree (Makefile/Kconfig/symlink) |
| `vendor-digest.sh` | Pin/verify the vendored KernelSU-Next tree digest |
| `stage-kernel.sh` | Extract `Image` (+ DTB) into `out_kernel/` |
| `pack-ak3.sh` | Assemble the AnyKernel3 payload |
| `verify-bundle.sh` | Collect the verification artifact |
| `pack-release.sh` | Pack artifacts, assert assets, select release files |
| `version-mwk.sh` | Write `localversion-moon` for the variant name |

The workflow never pipes a URL into `bash`. Each `setupLink` / `additional_script_link`
is resolved to `ci/<basename>`; if the URL points into this repository, the fetch is
compared byte-for-byte against the committed copy and the build fails on drift.

## Vendored KernelSU-Next

`kernelsu/KernelSU-Next/UPSTREAM` records `repo`, `branch`, `commit`, `tag`,
`commit_count`, `ksu_version` and the content pin `tree_sha256`. The build pins the
reported version via `KSU_VERSION_OVERRIDE` (from `configs/release/*.json`, currently
`33226` = `30000 + 3026 + 200`).

`tree_sha256` starts empty (advisory): the first run prints the current digest and the
build continues. Pin it once, after re-auditing the vendored tree:

```sh
sh ci/vendor-digest.sh --write    # writes tree_sha256 into UPSTREAM
sh ci/vendor-digest.sh --check    # CI runs this; fails on drift
```

`ksun-moonwake.sh` also enforces that the config's `setupArg` matches the `branch=` in
`UPSTREAM` — a vendored tree cannot be re-pointed at another ref, so a mismatch is an
error rather than a silently ignored argument.

## Known follow-ups

- Action refs are pinned by major tag (`checkout@v4`, `upload-artifact@v4`,
  `action-gh-release@v2`, `TelegramFileUploader@v1.1.1`). Pin to commit SHAs when you
  have them: `gh api repos/OWNER/REPO/commits/REF --jq .sha`.
- `configs/release/compression-c2g.json` is quarantined in place; move it to
  `configs/archive/` with `git rm`/`git add` when you want the release dir clean.
