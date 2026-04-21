#!/bin/bash
# build_proj.sh — builds PROJ for ios-arm64, ios-arm64-simulator, macos-arm64
# and packages it as libproj.xcframework
# PRD §7-3: no CURL, no TIFF, no apps, no tests
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=scripts/common.sh
source "${SCRIPT_DIR}/common.sh"
# shellcheck source=scripts/versions.sh
source "${SCRIPT_DIR}/versions.sh"

PKG="proj"
VERSION="${PROJ_VERSION}"
SRC="${PKG}-${VERSION}"
URL="https://download.osgeo.org/proj/proj-${VERSION}.tar.gz"
# compute after first download: shasum -a 256 proj-${VERSION}.tar.gz
SHA256="af5b731c145c1d13c4e3b4eeb7d167e94e845e440f71e3496b4ed8dae0291960"

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
        -DENABLE_CURL=OFF \
        -DENABLE_TIFF=OFF \
        -DBUILD_TESTING=OFF \
        -DBUILD_PROJSYNC=OFF \
        -DBUILD_APPS=OFF
done

log "[${PKG}] Assembling xcframeworks..."
for slice in ios-arm64 ios-arm64-simulator macos-arm64; do
    make_framework \
        "${FW_STAGING}/${slice}" "libproj" \
        "${INSTALL_BASE}/${slice}/lib/libproj.dylib" \
        "${INSTALL_BASE}/${slice}/include" \
        "$(slice_to_min_os "${slice}")" \
        "$(slice_to_platform "${slice}")"
done

make_xcframework "libproj" \
    "${FW_STAGING}/ios-arm64/libproj.framework" \
    "${FW_STAGING}/ios-arm64-simulator/libproj.framework" \
    "${FW_STAGING}/macos-arm64/libproj.framework"

log "[${PKG}] Done."
