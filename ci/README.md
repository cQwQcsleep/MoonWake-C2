# MoonWake C2 monorepo

Single repository for building MoonWake 2.7.0 C2.

- Kernel source: branch `c2` (C2 commit tree)
- CI workflow: `.github/workflows/build.yml`
- Build config: `configs/release/compression-c2.json`
- Scripts: `ci/`

## Build

GitHub Actions -> Build MoonWake Kernel -> Run workflow:

- config_type: release
- config_file: compression-c2.json
- full_dump: false
- send_to_telegram: false

Outputs:

- `MoonWake_2.7.0_C2_ak3.zip`: AnyKernel3 flashable zip artifact.
- `verify-<run_number>`: verification artifact containing `MoonWake_2.7.0_C2_config.txt`, `MoonWake_2.7.0_C2_System.map`, and `MoonWake_2.7.0_C2_ksu.txt`.

## Vendored dependencies

- `anykernel3/` is vendored; the workflow uses it directly (`AnyKernel3.repo = local`).
- `kernelsu/KernelSU-Next/` is vendored; `ci/ksun-moonwake.sh` uses it directly. Its upstream branch and commit are recorded in `kernelsu/KernelSU-Next/UPSTREAM`, and the build pins `KSU_VERSION_OVERRIDE` from `configs/release/compression-c2.json`.
- The clang toolchain is still downloaded as a compiler binary; it is not a project source dependency.
