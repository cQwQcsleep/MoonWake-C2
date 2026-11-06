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

- `MoonWake_2.7.0_C2_ak3.zip`
- `MoonWake_2.7.0_C2_config.txt`
- `MoonWake_2.7.0_C2_System.map`
- `MoonWake_2.7.0_C2_ksu.txt`
