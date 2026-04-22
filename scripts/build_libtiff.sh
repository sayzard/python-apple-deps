#!/bin/bash
# build_libtiff.sh — builds libtiff for ios-arm64, ios-arm64-simulator, macos-arm64
# and packages it as libtiff.xcframework
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=scripts/common.sh
source "${SCRIPT_DIR}/common.sh"
# shellcheck source=scripts/versions.sh
source "${SCRIPT_DIR}/versions.sh"

PKG="libtiff"
VERSION="${LIBTIFF_VERSION}"
SRC="tiff-${VERSION}"
URL="https://download.osgeo.org/libtiff/tiff-${VERSION}.tar.gz"
# compute after first download: shasum -a 256 tiff-${VERSION}.tar.gz
SHA256="f698d94f3103da8ca7438d84e0344e453fe0ba3b7486e04c5bf7a9a3fabe9b69"

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
        -Dtiff-tests=OFF \
        -Dtiff-tools=OFF \
        -Dtiff-docs=OFF
done

log "[${PKG}] Building static slices..."
for slice in ios-arm64 ios-arm64-simulator macos-arm64; do
    cmake_build_slice "${slice}" \
        "${SRC_DIR}/${SRC}" \
        "${BUILD_BASE}/cmake_static_${slice}" \
        "${INSTALL_BASE_STATIC}/${slice}" \
        -Dtiff-tests=OFF \
        -Dtiff-tools=OFF \
        -Dtiff-docs=OFF \
        -DBUILD_SHARED_LIBS=OFF
done

log "[${PKG}] Assembling xcframeworks..."
for slice in ios-arm64 ios-arm64-simulator macos-arm64; do
    make_framework \
        "${FW_STAGING}/${slice}" "libtiff" \
        "${INSTALL_BASE}/${slice}/lib/libtiff.dylib" \
        "${INSTALL_BASE}/${slice}/include" \
        "$(slice_to_min_os "${slice}")" \
        "$(slice_to_platform "${slice}")"
    add_static_lib \
        "${FW_STAGING}/${slice}" "libtiff" \
        "${INSTALL_BASE_STATIC}/${slice}/lib/libtiff.a"
done

make_xcframework "libtiff" \
    "${FW_STAGING}/ios-arm64/libtiff.framework" \
    "${FW_STAGING}/ios-arm64-simulator/libtiff.framework" \
    "${FW_STAGING}/macos-arm64/libtiff.framework"

log "[${PKG}] Done."
