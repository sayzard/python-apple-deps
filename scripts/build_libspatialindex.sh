#!/bin/bash
# build_libspatialindex.sh — builds libspatialindex for ios-arm64, ios-arm64-simulator, macos-arm64
# and packages two xcframeworks: libspatialindex and libspatialindex_c
# libspatialindex_c links against libspatialindex; rewrite_dep fixes the embedded rpath.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=scripts/common.sh
source "${SCRIPT_DIR}/common.sh"
# shellcheck source=scripts/versions.sh
source "${SCRIPT_DIR}/versions.sh"

PKG="libspatialindex"
VERSION="${LIBSPATIALINDEX_VERSION}"
SRC="spatialindex-src-${VERSION}"
URL="https://github.com/libspatialindex/libspatialindex/releases/download/${VERSION}/spatialindex-src-${VERSION}.tar.bz2"
# Fill in after first download: shasum -a 256 spatialindex-src-${VERSION}.tar.bz2
SHA256="c59932395e98896038d59199f2e2453595df6d730ffbe09d69df2a661bcb619b"

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
        "${INSTALL_BASE}/${slice}"
    # (no extra cmake flags needed beyond CMAKE_COMMON defaults)
done

log "[${PKG}] Assembling xcframeworks..."
for slice in ios-arm64 ios-arm64-simulator macos-arm64; do
    local_min_os="$(slice_to_min_os "${slice}")"
    local_platform="$(slice_to_platform "${slice}")"

    # libspatialindex (C++ API)
    make_framework \
        "${FW_STAGING}/${slice}" "libspatialindex" \
        "${INSTALL_BASE}/${slice}/lib/libspatialindex.dylib" \
        "${INSTALL_BASE}/${slice}/include" \
        "${local_min_os}" \
        "${local_platform}"

    # libspatialindex_c (C API) — depends on libspatialindex
    make_framework \
        "${FW_STAGING}/${slice}" "libspatialindex_c" \
        "${INSTALL_BASE}/${slice}/lib/libspatialindex_c.dylib" \
        "${INSTALL_BASE}/${slice}/include" \
        "${local_min_os}" \
        "${local_platform}"

    # Rewrite the embedded libspatialindex dependency inside libspatialindex_c
    # Use "libspatialindex." (with dot) to avoid matching libspatialindex_c.*
    rewrite_dep \
        "${FW_STAGING}/${slice}/libspatialindex_c.framework/libspatialindex_c" \
        "libspatialindex." \
        "libspatialindex"
done

make_xcframework "libspatialindex" \
    "${FW_STAGING}/ios-arm64/libspatialindex.framework" \
    "${FW_STAGING}/ios-arm64-simulator/libspatialindex.framework" \
    "${FW_STAGING}/macos-arm64/libspatialindex.framework"

make_xcframework "libspatialindex_c" \
    "${FW_STAGING}/ios-arm64/libspatialindex_c.framework" \
    "${FW_STAGING}/ios-arm64-simulator/libspatialindex_c.framework" \
    "${FW_STAGING}/macos-arm64/libspatialindex_c.framework"

log "[${PKG}] Done."
