#!/bin/bash
# build_libzmq.sh — builds ZeroMQ for ios-arm64, ios-arm64-simulator, macos-arm64
# and packages it as libzmq.xcframework
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=scripts/common.sh
source "${SCRIPT_DIR}/common.sh"
# shellcheck source=scripts/versions.sh
source "${SCRIPT_DIR}/versions.sh"

PKG="libzmq"
VERSION="${LIBZMQ_VERSION}"
SRC="zeromq-${VERSION}"
URL="https://github.com/zeromq/libzmq/releases/download/v${VERSION}/zeromq-${VERSION}.tar.gz"
# Fill in after first download: shasum -a 256 zeromq-${VERSION}.tar.gz
SHA256="6653ef5910f17954861fe72332e68b03ca6e4d9c7160eb3a8de5a5a913bfab43"

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
        -DWITH_PERF_TOOL=OFF \
        -DZMQ_BUILD_TESTS=OFF \
        -DENABLE_CPACK=OFF \
        -DBUILD_SHARED=ON \
        -DBUILD_STATIC=OFF
done

log "[${PKG}] Assembling xcframework..."
for slice in ios-arm64 ios-arm64-simulator macos-arm64; do
    make_framework \
        "${FW_STAGING}/${slice}" "libzmq" \
        "${INSTALL_BASE}/${slice}/lib/libzmq.dylib" \
        "${INSTALL_BASE}/${slice}/include" \
        "$(slice_to_min_os "${slice}")" \
        "$(slice_to_platform "${slice}")"
done

make_xcframework "libzmq" \
    "${FW_STAGING}/ios-arm64/libzmq.framework" \
    "${FW_STAGING}/ios-arm64-simulator/libzmq.framework" \
    "${FW_STAGING}/macos-arm64/libzmq.framework"

log "[${PKG}] Done."
