#!/bin/bash
# build_liblzma.sh — builds liblzma (xz) for ios-arm64, ios-arm64-simulator, macos-arm64
# and packages it as liblzma.xcframework
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=scripts/common.sh
source "${SCRIPT_DIR}/common.sh"
# shellcheck source=scripts/versions.sh
source "${SCRIPT_DIR}/versions.sh"

PKG="xz"
VERSION="${LZMA_VERSION}"
SRC="${PKG}-${VERSION}"
URL="https://github.com/tukaani-project/xz/releases/download/v${VERSION}/xz-${VERSION}.tar.gz"
# compute after first download: shasum -a 256 xz-${VERSION}.tar.gz
SHA256="3d3a1b973af218114f4f889bbaa2f4c037deaae0c8e815eec381c3d546b974a0"

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
        -DBUILD_TESTING=OFF \
        -DBUILD_SHARED_LIBS=ON
done

log "[${PKG}] Building static slices..."
for slice in ios-arm64 ios-arm64-simulator macos-arm64; do
    cmake_build_slice "${slice}" \
        "${SRC_DIR}/${SRC}" \
        "${BUILD_BASE}/cmake_static_${slice}" \
        "${INSTALL_BASE_STATIC}/${slice}" \
        -DBUILD_TESTING=OFF \
        -DBUILD_SHARED_LIBS=OFF
done

log "[${PKG}] Assembling xcframeworks..."
for slice in ios-arm64 ios-arm64-simulator macos-arm64; do
    make_framework \
        "${FW_STAGING}/${slice}" "liblzma" \
        "${INSTALL_BASE}/${slice}/lib/liblzma.dylib" \
        "${INSTALL_BASE}/${slice}/include" \
        "$(slice_to_min_os "${slice}")" \
        "$(slice_to_platform "${slice}")"
    add_static_lib \
        "${FW_STAGING}/${slice}" "liblzma" \
        "${INSTALL_BASE_STATIC}/${slice}/lib/liblzma.a"
done

make_xcframework "liblzma" \
    "${FW_STAGING}/ios-arm64/liblzma.framework" \
    "${FW_STAGING}/ios-arm64-simulator/liblzma.framework" \
    "${FW_STAGING}/macos-arm64/liblzma.framework"

log "[${PKG}] Done."
