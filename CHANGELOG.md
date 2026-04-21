# Changelog

All notable changes to this project will be documented in this file.
Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

## [2.0.0] - 2026-04-21

### Added
- arm64 iOS Simulator slice (`ios-arm64-simulator`) — Apple Silicon native
- zlib 1.3.2 xcframework
- libheif 1.20.2 xcframework (was WIP in v1.0)
- GitHub Actions CI: shellcheck lint, build verification, automated Release
- `tests/verify_xcframework.sh` — automated xcframework validation
- `package_xcframeworks.sh` — reproducible zip packaging with checksums
- Swift Package Manager: all 21 products now exposed (v1.0 was missing 5)
- CocoaPods: `Python-aux.podspec` with 21 subspecs
- `THIRD_PARTY_LICENSES.md` documenting all package licenses

### Changed
- **All packages updated to latest stable versions** (2026-04-21)
- iOS minimum deployment target: 14.0 → **16.0**
- macOS minimum deployment target: added explicit 13.0
- GDAL: autoconf → **cmake only** (required since 3.9)
- libjpeg-9d → **libjpeg-turbo 3.1.4** (API compatible, 2–4× faster)
- x86_64 iOS Simulator → **arm64** Simulator
- Error handling: silent failures → `set -euo pipefail` + `trap ERR`
- OpenBLAS: hardcoded gfortran path → `brew --prefix gcc` auto-detection

### Fixed
- Swift Package.swift missing `gdal`, `geos`, `proj`, `spatialindex`, `lzma` products
- Reproducible builds: all sources fetched at pinned versions with SHA256 verification

### Security
- liblzma: pinned to 5.8.3 (CVE-2024-3094 safe lineage)
- libheif: pinned to 1.20.2 (CVE-2026-3950 not present)
- OpenSSL: 4.0.0 intentionally excluded; using 3.4.x LTS

## [1.0] - 2023-09-01

- Initial release by holzschu/Python-aux
