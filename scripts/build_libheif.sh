#!/bin/bash
# build_libheif.sh — builds libheif (static) for ios-arm64, ios-arm64-simulator, macos-arm64
# and packages it as libheif.xcframework using -library (static xcframework)
# PRD §7-4: static build, no de265/x265/aom codec deps
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=scripts/common.sh
source "${SCRIPT_DIR}/common.sh"
# shellcheck source=scripts/versions.sh
source "${SCRIPT_DIR}/versions.sh"

PKG="libheif"
VERSION="${LIBHEIF_VERSION}"
SRC="${PKG}-${VERSION}"
URL="https://github.com/strukturag/libheif/releases/download/v${VERSION}/libheif-${VERSION}.tar.gz"
# compute after first download: shasum -a 256 libheif-${VERSION}.tar.gz
SHA256="68ac9084243004e0ef3633f184eeae85d615fe7e4444373a0a21cebccae9d12a"

BUILD_BASE="${ROOT_DIR}/build/${PKG}"
INSTALL_BASE="${BUILD_BASE}/install"

log "[${PKG}] Fetching sources..."
fetch_source "${SRC}" "${URL}" "${SHA256}"

log "[${PKG}] Building slices (static)..."
for slice in ios-arm64 ios-arm64-simulator macos-arm64; do
    cmake_build_slice "${slice}" \
        "${SRC_DIR}/${SRC}" \
        "${BUILD_BASE}/cmake_${slice}" \
        "${INSTALL_BASE}/${slice}" \
        -DBUILD_SHARED_LIBS=OFF \
        -DWITH_EXAMPLES=OFF \
        -DWITH_LIBDE265=OFF \
        -DWITH_X265=OFF \
        -DWITH_AOM_DECODER=OFF \
        -DWITH_AOM_ENCODER=OFF \
        -DENABLE_TESTING=OFF \
        -DWITH_GDK_PIXBUF=OFF \
        -DWITH_REDUCED_VISIBILITY=OFF
done

log "[${PKG}] Assembling static xcframework..."
OUTPUT="${XCFW_OUT}/libheif.xcframework"
rm -rf "${OUTPUT}"

xcodebuild -create-xcframework \
    -library "${INSTALL_BASE}/ios-arm64/lib/libheif.a" \
    -headers "${INSTALL_BASE}/ios-arm64/include/libheif" \
    -library "${INSTALL_BASE}/ios-arm64-simulator/lib/libheif.a" \
    -headers "${INSTALL_BASE}/ios-arm64-simulator/include/libheif" \
    -library "${INSTALL_BASE}/macos-arm64/lib/libheif.a" \
    -headers "${INSTALL_BASE}/macos-arm64/include/libheif" \
    -output "${OUTPUT}"

log "[OK] ${OUTPUT}"
log "[${PKG}] Done."
