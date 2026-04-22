#!/bin/bash
# build_libpng.sh — builds libpng for ios-arm64, ios-arm64-simulator, macos-arm64
# and packages it as libpng.xcframework (a-Shell compatible name)
# Source tarball from GitHub extracts as libpng-${LIBPNG_VERSION}/
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=scripts/common.sh
source "${SCRIPT_DIR}/common.sh"
# shellcheck source=scripts/versions.sh
source "${SCRIPT_DIR}/versions.sh"

PKG="libpng"
VERSION="${LIBPNG_VERSION}"
SRC="${PKG}-${VERSION}"
URL="https://github.com/pnggroup/libpng/archive/refs/tags/v${VERSION}.tar.gz"
# compute after first download: shasum -a 256 v${VERSION}.tar.gz
SHA256="a9d4df463d36a6e5f9c29bd6f4967312d17e996c1854f3511f833924eb1993cf"

BUILD_BASE="${ROOT_DIR}/build/${PKG}"
INSTALL_BASE="${BUILD_BASE}/install"
INSTALL_BASE_STATIC="${BUILD_BASE}/install_static"
FW_STAGING="${BUILD_BASE}/frameworks"

log "[${PKG}] Fetching sources..."
fetch_source "${SRC}" "${URL}" "${SHA256}"

log "[${PKG}] Building shared slices..."
for slice in ios-arm64 ios-arm64-simulator macos-arm64; do
    cmake_build_slice "${slice}" \
        "${SRC_DIR}/${SRC}" \
        "${BUILD_BASE}/cmake_${slice}" \
        "${INSTALL_BASE}/${slice}" \
        -DPNG_TESTS=OFF \
        -DPNG_SHARED=ON \
        -DPNG_STATIC=OFF
done

log "[${PKG}] Building static slices..."
for slice in ios-arm64 ios-arm64-simulator macos-arm64; do
    cmake_build_slice "${slice}" \
        "${SRC_DIR}/${SRC}" \
        "${BUILD_BASE}/cmake_static_${slice}" \
        "${INSTALL_BASE_STATIC}/${slice}" \
        -DPNG_TESTS=OFF \
        -DPNG_SHARED=OFF \
        -DPNG_STATIC=ON \
        -DBUILD_SHARED_LIBS=OFF
done

log "[${PKG}] Assembling xcframeworks..."
# libpng installs as libpng16.dylib/libpng16.a (may be a symlink chain); cp -L resolves it
for slice in ios-arm64 ios-arm64-simulator macos-arm64; do
    make_framework \
        "${FW_STAGING}/${slice}" "libpng" \
        "${INSTALL_BASE}/${slice}/lib/libpng16.dylib" \
        "${INSTALL_BASE}/${slice}/include" \
        "$(slice_to_min_os "${slice}")" \
        "$(slice_to_platform "${slice}")"
    add_static_lib \
        "${FW_STAGING}/${slice}" "libpng" \
        "${INSTALL_BASE_STATIC}/${slice}/lib/libpng16.a"
done

make_xcframework "libpng" \
    "${FW_STAGING}/ios-arm64/libpng.framework" \
    "${FW_STAGING}/ios-arm64-simulator/libpng.framework" \
    "${FW_STAGING}/macos-arm64/libpng.framework"

log "[${PKG}] Done."
