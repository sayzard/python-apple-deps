#!/bin/bash
# build_geos.sh — builds GEOS for ios-arm64, ios-arm64-simulator, macos-arm64
# and packages two xcframeworks: libgeos (C++ API) and libgeos_c (C API)
# PRD §7-2: libgeos_c depends on libgeos; rewrite_dep fixes the embedded dylib path
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=scripts/common.sh
source "${SCRIPT_DIR}/common.sh"
# shellcheck source=scripts/versions.sh
source "${SCRIPT_DIR}/versions.sh"

PKG="geos"
VERSION="${GEOS_VERSION}"
SRC="${PKG}-${VERSION}"
URL="https://download.osgeo.org/geos/geos-${VERSION}.tar.bz2"
# compute after first download: shasum -a 256 geos-${VERSION}.tar.bz2
SHA256="3c20919cda9a505db07b5216baa980bacdaa0702da715b43f176fb07eff7e716"

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
        -DGEOS_ENABLE_TESTS=OFF
done

log "[${PKG}] Assembling xcframeworks..."
for slice in ios-arm64 ios-arm64-simulator macos-arm64; do
    local_min_os="$(slice_to_min_os "${slice}")"
    local_platform="$(slice_to_platform "${slice}")"

    # libgeos (C++ API)
    make_framework \
        "${FW_STAGING}/${slice}" "libgeos" \
        "${INSTALL_BASE}/${slice}/lib/libgeos.dylib" \
        "${INSTALL_BASE}/${slice}/include" \
        "${local_min_os}" \
        "${local_platform}"

    # libgeos_c (C API) — depends on libgeos
    make_framework \
        "${FW_STAGING}/${slice}" "libgeos_c" \
        "${INSTALL_BASE}/${slice}/lib/libgeos_c.dylib" \
        "${INSTALL_BASE}/${slice}/include" \
        "${local_min_os}" \
        "${local_platform}"

    # Rewrite the embedded libgeos dependency inside libgeos_c to use @rpath
    # Use "libgeos." pattern (with dot) to match libgeos.dylib but not libgeos_c.*
    rewrite_dep \
        "${FW_STAGING}/${slice}/libgeos_c.framework/libgeos_c" \
        "libgeos." \
        "libgeos"
done

make_xcframework "libgeos" \
    "${FW_STAGING}/ios-arm64/libgeos.framework" \
    "${FW_STAGING}/ios-arm64-simulator/libgeos.framework" \
    "${FW_STAGING}/macos-arm64/libgeos.framework"

make_xcframework "libgeos_c" \
    "${FW_STAGING}/ios-arm64/libgeos_c.framework" \
    "${FW_STAGING}/ios-arm64-simulator/libgeos_c.framework" \
    "${FW_STAGING}/macos-arm64/libgeos_c.framework"

log "[${PKG}] Done."
