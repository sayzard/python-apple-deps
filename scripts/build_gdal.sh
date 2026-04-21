#!/bin/bash
# build_gdal.sh — builds GDAL for ios-arm64, ios-arm64-simulator, macos-arm64
# and packages it as libgdal.xcframework
# PRD §7-1: GDAL 3.9+ is cmake-only.
# Links GEOS and PROJ from their per-slice install prefixes (must be built first).
# After framework assembly, LC_LOAD_DYLIB entries are rewritten to @rpath.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=scripts/common.sh
source "${SCRIPT_DIR}/common.sh"
# shellcheck source=scripts/versions.sh
source "${SCRIPT_DIR}/versions.sh"

PKG="gdal"
VERSION="${GDAL_VERSION}"
SRC="gdal-${VERSION}"
URL="https://github.com/OSGeo/gdal/releases/download/v${VERSION}/gdal-${VERSION}.tar.gz"
SHA256="1fdfe51181d08b9b83037b611da4de4a7cf1fca69e6564945ac99d3f7d0367dd"

BUILD_BASE="${ROOT_DIR}/build/${PKG}"
INSTALL_BASE="${BUILD_BASE}/install"
FW_STAGING="${BUILD_BASE}/frameworks"

GEOS_BASE="${ROOT_DIR}/build/geos/install"
PROJ_BASE="${ROOT_DIR}/build/proj/install"

log "[${PKG}] Fetching sources..."
fetch_source "${SRC}" "${URL}" "${SHA256}"

log "[${PKG}] Building slices..."
for slice in ios-arm64 ios-arm64-simulator macos-arm64; do
    geos_dir="${GEOS_BASE}/${slice}/lib/cmake/GEOS"
    proj_dir="${PROJ_BASE}/${slice}/lib/cmake/proj"

    if [[ ! -f "${geos_dir}/GEOS-config.cmake" ]]; then
        log "[WARN] GEOS cmake config not found for ${slice} — build geos first"
    fi
    if [[ ! -f "${proj_dir}/proj-config.cmake" ]]; then
        log "[WARN] PROJ cmake config not found for ${slice} — build proj first"
    fi

    cmake_build_slice "${slice}" \
        "${SRC_DIR}/${SRC}" \
        "${BUILD_BASE}/cmake_${slice}" \
        "${INSTALL_BASE}/${slice}" \
        -DGDAL_BUILD_OPTIONAL_DRIVERS=OFF \
        -DOGR_BUILD_OPTIONAL_DRIVERS=OFF \
        -DBUILD_SHARED_LIBS=ON \
        -DGDAL_USE_GEOS=ON \
        -DGEOS_DIR="${geos_dir}" \
        -DGDAL_USE_PROJ=ON \
        -DPROJ_DIR="${proj_dir}" \
        -DGDAL_USE_TIFF_INTERNAL=ON \
        -DGDAL_USE_GEOTIFF_INTERNAL=ON \
        -DGDAL_USE_PNG_INTERNAL=ON \
        -DGDAL_USE_JPEG_INTERNAL=ON \
        -DGDAL_USE_JPEG=OFF \
        -DGDAL_USE_JPEG12_INTERNAL=OFF \
        -DGDAL_USE_ZLIB_INTERNAL=ON \
        -DBUILD_TESTING=OFF \
        -DBUILD_APPS=OFF
done

log "[${PKG}] Assembling xcframework..."
for slice in ios-arm64 ios-arm64-simulator macos-arm64; do
    make_framework \
        "${FW_STAGING}/${slice}" "libgdal" \
        "${INSTALL_BASE}/${slice}/lib/libgdal.dylib" \
        "${INSTALL_BASE}/${slice}/include" \
        "$(slice_to_min_os "${slice}")" \
        "$(slice_to_platform "${slice}")"

    # Rewrite GEOS/PROJ deps to @rpath inside libgdal
    rewrite_dep \
        "${FW_STAGING}/${slice}/libgdal.framework/libgdal" \
        "libgeos_c" "libgeos_c"
    rewrite_dep \
        "${FW_STAGING}/${slice}/libgdal.framework/libgdal" \
        "libgeos." "libgeos"
    rewrite_dep \
        "${FW_STAGING}/${slice}/libgdal.framework/libgdal" \
        "libproj" "libproj"
done

make_xcframework "libgdal" \
    "${FW_STAGING}/ios-arm64/libgdal.framework" \
    "${FW_STAGING}/ios-arm64-simulator/libgdal.framework" \
    "${FW_STAGING}/macos-arm64/libgdal.framework"

log "[${PKG}] Done."
