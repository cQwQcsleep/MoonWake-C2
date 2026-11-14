# MoonWake C2 monorepo

Single repository for building MoonWake 2.7.0 C2.

- Kernel source: branch `c2` (C2 commit tree)
- CI workflow: `.github/workflows/build.yml`
- Build configs: `configs/release/compression-c2a.json` … `compression-c2f.json`
- Scripts: `ci/`

## Build

GitHub Actions -> Build MoonWake Kernel -> Run workflow:

- config_type: release
- config_file: leave blank to build all C2A–C2F variants in parallel, or set e.g. `compression-c2f.json`
- full_dump: false
- send_to_telegram: false

Variants: C2A (base), C2B (GPU OC), C2C (CPU 2.8GHz), C2D (GPU + CPU 2.8GHz), C2E (CPU 2.8/3.0GHz), C2F (GPU + CPU 2.8/3.0GHz).

Outputs:

- `<kernel>_ak3.zip`: AnyKernel3 flashable zip artifact per variant.
- `verify-<run_number>`: verification artifact containing config, System.map and ksu metadata for every variant.
- GitHub Release: one release per variant after every successful build, tagged like `mwk-2.7.0-c2b-<run_number>`, with that variant's ak3 zip, System.map, config and ksu metadata.

## Vendored dependencies

- `anykernel3/` is vendored; the workflow uses it directly (`AnyKernel3.repo = local`).
- `kernelsu/KernelSU-Next/` is vendored; `ci/ksun-moonwake.sh` uses it directly. Its upstream branch and commit are recorded in `kernelsu/KernelSU-Next/UPSTREAM`, and the build pins `KSU_VERSION_OVERRIDE` from `configs/release/compression-c2.json`.
- The clang toolchain is still downloaded as a compiler binary; it is not a project source dependency.
