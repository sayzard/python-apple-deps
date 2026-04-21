#!/bin/bash
# build_zlib.sh — builds zlib for ios-arm64, ios-arm64-simulator, macos-arm64
# and packages it as libz.xcframework
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=scripts/common.sh
source "${SCRIPT_DIR}/common.sh"
# shellcheck source=scripts/versions.sh
source "${SCRIPT_DIR}/versions.sh"

PKG="zlib"
VERSION="${ZLIB_VERSION}"
SRC="${PKG}-${VERSION}"
URL="https://zlib.net/zlib-${VERSION}.tar.gz"
# compute after first download: shasum -a 256 zlib-${VERSION}.tar.gz
SHA256="bb329a0a2cd0274d05519d61c667c062e06990d72e125ee2dfa8de64f0119d16"

BUILD_BASE="${ROOT_DIR}/build/${PKG}"
INSTALL_BASE="${BUILD_BASE}/install"
FW_STAGING="${BUILD_BASE}/frameworks"

log "[${PKG}] Fetching sources..."
fetch_source "${SRC}" "${URL}" "${SHA256}"

log "[${PKG}] Building slices..."
for slice in ios-arm64 ios-arm64-simulator macos-arm64; do
    cmake_build_slice "${slice}" \
        "${SRC_DIR}/${SRC}" \
        "${BUILD_BASE}/cmake_${slice}" \
        "${INSTALL_BASE}/${slice}" \
        -DZLIB_BUILD_EXAMPLES=OFF \
        -DZLIB_BUILD_SHARED=ON
done

log "[${PKG}] Assembling xcframeworks..."
for slice in ios-arm64 ios-arm64-simulator macos-arm64; do
    make_framework \
        "${FW_STAGING}/${slice}" "libz" \
        "${INSTALL_BASE}/${slice}/lib/libz.dylib" \
        "${INSTALL_BASE}/${slice}/include" \
        "$(slice_to_min_os "${slice}")" \
        "$(slice_to_platform "${slice}")"
done

make_xcframework "libz" \
    "${FW_STAGING}/ios-arm64/libz.framework" \
    "${FW_STAGING}/ios-arm64-simulator/libz.framework" \
    "${FW_STAGING}/macos-arm64/libz.framework"

log "[${PKG}] Done."
