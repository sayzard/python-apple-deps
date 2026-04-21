# Python-aux

> Rebuilt xcframeworks of Python's native C-extension dependencies for iOS and macOS (Apple Silicon).
> Drop-in replacement for [holzschu/Python-aux](https://github.com/holzschu/Python-aux) with updated packages, arm64 Simulator support, and reproducible builds.

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Build](https://github.com/your-username/Python-aux/actions/workflows/release.yml/badge.svg)

## Supported Slices

| Slice | Architecture | Use |
|-------|-------------|-----|
| `ios-arm64` | arm64, iOS SDK | Physical device |
| `ios-arm64-simulator` | arm64, iOS Simulator SDK | Apple Silicon Mac simulator |
| `macos-arm64` | arm64, macOS SDK | macOS / Python runtime |

## Package Versions

| Package | Version | Notes |
|---------|---------|-------|
| OpenSSL | 3.4.1 | 3.4.x LTS; 4.0.0 intentionally excluded |
| libffi | 3.5.2 | |
| liblzma (xz) | 5.8.3 | CVE-2024-3094 clean lineage |
| zlib | 1.3.2 | |
| libjpeg-turbo | 3.1.4 | Replaces libjpeg-9d; API compatible |
| libpng | 1.6.58 | |
| libtiff | 4.7.1 | |
| libheif | 1.20.2 | 1.21.2 excluded: CVE-2026-3950 |
| FreeType | 2.14.2 | |
| HarfBuzz | 10.4.0 | |
| GEOS | 3.14.1 | |
| PROJ | 9.8.1 | |
| GDAL | 3.12.3 | cmake-only (3.9+) |
| libspatialindex | 2.1.0 | |
| FFTW3 | 3.3.10 | |
| OpenBLAS | 0.3.32 | |
| libxslt | 1.1.45 | ⚠ End of maintenance Jul 2025 |
| libzmq | 4.3.5 | |

## xcframeworks

| Name | Source |
|------|--------|
| `openssl.xcframework` | OpenSSL libssl |
| `crypto.xcframework` | OpenSSL libcrypto |
| `liblzma.xcframework` | xz/liblzma |
| `libffi.xcframework` | libffi |
| `libjpeg.xcframework` | libjpeg-turbo |
| `libpng.xcframework` | libpng |
| `libtiff.xcframework` | libtiff |
| `libheif.xcframework` | libheif |
| `freetype.xcframework` | FreeType |
| `harfbuzz.xcframework` | HarfBuzz |
| `libgeos.xcframework` | GEOS C++ |
| `libgeos_c.xcframework` | GEOS C API |
| `libproj.xcframework` | PROJ |
| `libgdal.xcframework` | GDAL |
| `libspatialindex.xcframework` | libspatialindex C++ |
| `libspatialindex_c.xcframework` | libspatialindex C API |
| `libfftw3.xcframework` | FFTW3 |
| `libfftw3_threads.xcframework` | FFTW3 threads |
| `openblas.xcframework` | OpenBLAS |
| `libxslt.xcframework` | libxslt |
| `libexslt.xcframework` | libexslt |
| `libzmq.xcframework` | libzmq |

## Requirements

- macOS 14.0+ (Apple Silicon)
- Xcode 16.0+
- cmake 4.0+ (`brew install cmake`)
- `brew install automake libtool pkg-config gcc` (for gfortran / non-cmake builds)

## Quick Start — Swift Package Manager

```swift
// Package.swift
.package(url: "https://github.com/your-username/Python-aux", from: "2.0.0")
```

Select the frameworks you need in your target's dependencies.

## Drop-in Replacement for a-Shell / Carnets

a-Shell uses `holzschu/cpython`'s `downloadFrameworks.sh` to pull xcframeworks.
To switch to this build, edit `downloadFrameworks.sh`:

```bash
# Change:
BASE_URL="https://github.com/holzschu/Python-aux/releases/download/1.0"
# To:
BASE_URL="https://github.com/your-username/Python-aux/releases/download/v2.0.0"
```

**Note**: Minimum OS version changed from 14.0 to **16.0**. Update your Xcode project's deployment target accordingly.

## Build from Source

```bash
git clone https://github.com/your-username/Python-aux.git
cd Python-aux

# Install prerequisites
brew install cmake automake libtool pkg-config gcc

# Build all packages (30–60 min on Apple Silicon)
./build_all.sh

# Package xcframeworks for distribution
./package_xcframeworks.sh

# Verify
./tests/verify_xcframework.sh
```

## Verification

```bash
# Architecture check
file xcframeworks/libgdal.xcframework/ios-arm64/libgdal.framework/libgdal

# Install name check
otool -D xcframeworks/libgdal.xcframework/ios-arm64/libgdal.framework/libgdal

# Dependency check
otool -L xcframeworks/libgdal.xcframework/ios-arm64/libgdal.framework/libgdal
```

## Changes from holzschu/Python-aux 1.0

| Area | Original | This repo |
|------|----------|-----------|
| Package versions | 2–5 years old | Latest stable (2026) |
| iOS Simulator | x86_64 only | **arm64** (Apple Silicon native) |
| Min deployment target | iOS 14.0 | **iOS 16.0** / macOS 13.0 |
| GDAL build system | autoconf + patches | cmake only (required 3.9+) |
| libjpeg | libjpeg-9d | **libjpeg-turbo 3.1.4** |
| libheif | WIP | **1.20.2** |
| zlib | not built | **1.3.2** |
| Package.swift | 5 products missing | all 21 exposed |
| Error handling | silent `exit 0` | `set -euo pipefail` + trap |
| CI | none | GitHub Actions |

## License

MIT — see [LICENSE](LICENSE).

Third-party package licenses are documented in [THIRD_PARTY_LICENSES.md](THIRD_PARTY_LICENSES.md).
