#!/bin/bash
# build_libjpeg_turbo.sh — builds libjpeg-turbo for ios-arm64, ios-arm64-simulator, macos-arm64
# and packages it as libjpeg.xcframework (a-Shell drop-in compatible name)
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=scripts/common.sh
source "${SCRIPT_DIR}/common.sh"
# shellcheck source=scripts/versions.sh
source "${SCRIPT_DIR}/versions.sh"

PKG="libjpeg-turbo"
VERSION="${JPEG_TURBO_VERSION}"
SRC="${PKG}-${VERSION}"
URL="https://github.com/libjpeg-turbo/libjpeg-turbo/releases/download/${VERSION}/libjpeg-turbo-${VERSION}.tar.gz"
# compute after first download: shasum -a 256 libjpeg-turbo-${VERSION}.tar.gz
SHA256="e23d3ebb2c6ee4d0e2a5823dbb55b614845df5ea3435c956fed5cf04041a87ad"

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
        -DCMAKE_SYSTEM_PROCESSOR=arm64 \
        -DREQUIRE_SIMD=OFF \
        -DENABLE_SHARED=ON \
        -DENABLE_STATIC=OFF
done

log "[${PKG}] Assembling xcframeworks..."
for slice in ios-arm64 ios-arm64-simulator macos-arm64; do
    make_framework \
        "${FW_STAGING}/${slice}" "libjpeg" \
        "${INSTALL_BASE}/${slice}/lib/libjpeg.dylib" \
        "${INSTALL_BASE}/${slice}/include" \
        "$(slice_to_min_os "${slice}")" \
        "$(slice_to_platform "${slice}")"
done

# xcframework name is libjpeg for a-Shell drop-in compatibility
make_xcframework "libjpeg" \
    "${FW_STAGING}/ios-arm64/libjpeg.framework" \
    "${FW_STAGING}/ios-arm64-simulator/libjpeg.framework" \
    "${FW_STAGING}/macos-arm64/libjpeg.framework"

log "[${PKG}] Done."
