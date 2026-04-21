# Contributing to Python-aux

## Reporting Issues

- Use GitHub Issues with the bug report template
- Include: macOS version, Xcode version, cmake version, full error output

## Updating a Package Version

1. Edit `scripts/versions.sh` — bump the version constant
2. Update the download URL in the corresponding `scripts/build_*.sh`
3. Update `SHA256` — run `shasum -a 256 <downloaded-tarball>` after first run with empty SHA256
4. Update `README.md` package version table
5. Run `./build_all.sh` and `./tests/verify_xcframework.sh`
6. Submit a PR

## Adding a New Package

1. Create `scripts/build_<name>.sh` following the existing pattern
2. Add the version constant to `scripts/versions.sh`
3. Add the build call to `build_all.sh` at the correct dependency order position
4. Add the xcframework entry to `package_xcframeworks.sh`
5. Add a `binaryTarget` in `Package.swift`
6. Add a subspec in `Python-aux.podspec`
7. Document in `README.md` and `THIRD_PARTY_LICENSES.md`

## Pull Request Guidelines

- One PR per package or fix
- All scripts must pass `shellcheck`
- `./tests/verify_xcframework.sh` must pass for changed packages
- Describe why a version is chosen (stability, CVE fix, etc.)

## Code Style

- `set -euo pipefail` at top of every script
- Quote all variables: `"${VAR}"`
- Use `log()` from `common.sh` for progress output
- No silent error suppression (`|| true` only when truly safe)
