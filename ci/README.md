# MoonWake C2 monorepo

Single repository for building MoonWake 2.7.0 C2.

- Kernel source: branch `c2` (C2 commit tree)
- CI workflow: `.github/workflows/build.yml`
- Batch configs: `configs/release/compression-c2a.json` … `compression-c2f.json`
- C2G config: `configs/release/compression-c2g.json`
- Scripts: `ci/`

## Build

GitHub Actions -> Build MoonWake Kernel -> Run workflow:

- Batch: `config_type=release`, leave `config_file` blank to build C2, C2A–C2F in parallel.
- C2G: `config_type=release`, `config_file=compression-c2g.json`.
- full_dump: false
- send_to_telegram: false

Variants: C2A (base), C2B (GPU OC), C2C (CPU 2.8GHz), C2D (GPU + CPU 2.8GHz), C2E (CPU 2.8/3.0GHz), C2F (GPU + CPU 2.8/3.0GHz), C2G (report tuning values).

Outputs:

- `<kernel>_ak3.zip`: AnyKernel3 flashable zip artifact per variant.
- `verify-<kernel>-<run_number>`: per-variant verification artifact containing config, System.map and ksu metadata.
- GitHub Release: exactly one release per workflow run, tagged `mwk-2.7.0-<run_number>`, containing all variant assets built in that run.

## Vendored dependencies

- `anykernel3/` is vendored; the workflow uses it directly (`AnyKernel3.repo = local`).
- `kernelsu/KernelSU-Next/` is vendored; `ci/ksun-moonwake.sh` uses it directly. Its upstream branch and commit are recorded in `kernelsu/KernelSU-Next/UPSTREAM`, and the build pins `KSU_VERSION_OVERRIDE` from `configs/release/compression-c2.json`.
- The clang toolchain is still downloaded as a compiler binary; it is not a project source dependency.
