#!/bin/bash
# build_libffi.sh — builds libffi (autotools) for ios-arm64, ios-arm64-simulator, macos-arm64
# libffi does not support cmake; uses ./configure with cross-compilation flags.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=scripts/common.sh
source "${SCRIPT_DIR}/common.sh"
# shellcheck source=scripts/versions.sh
source "${SCRIPT_DIR}/versions.sh"

PKG="libffi"
VERSION="${LIBFFI_VERSION}"
SRC="${PKG}-${VERSION}"
URL="https://github.com/libffi/libffi/releases/download/v${VERSION}/libffi-${VERSION}.tar.gz"
SHA256="f3a3082a23b37c293a4fcd1053147b371f2ff91fa7ea1b2a52e335676bac82dc"

BUILD_BASE="${ROOT_DIR}/build/${PKG}"
INSTALL_BASE="${BUILD_BASE}/install"
FW_STAGING="${BUILD_BASE}/frameworks"

log "[${PKG}] Fetching sources..."
fetch_source "${SRC}" "${URL}" "${SHA256}"

build_ffi_slice() {
    local slice="$1"
    local install_prefix="${INSTALL_BASE}/${slice}"
    local build_dir="${BUILD_BASE}/build_${slice}"

    local cc cflags host
    case "${slice}" in
        ios-arm64)
            cc="$(xcrun -sdk iphoneos -find clang)"
            cflags="-arch arm64 -target arm64-apple-ios${IOS_MIN} -isysroot ${IOS_SDKROOT}"
            host="aarch64-apple-darwin"
            ;;
        ios-arm64-simulator)
            cc="$(xcrun -sdk iphonesimulator -find clang)"
            cflags="-arch arm64 -target arm64-apple-ios${IOS_MIN}-simulator -isysroot ${SIM_SDKROOT}"
            host="aarch64-apple-darwin"
            ;;
        macos-arm64)
            cc="$(xcrun -sdk macosx -find clang)"
            cflags="-arch arm64 -target arm64-apple-macos${MACOS_MIN} -isysroot ${OSX_SDKROOT}"
            host="aarch64-apple-darwin"
            ;;
    esac

    rm -rf "${build_dir}"
    mkdir -p "${build_dir}"

    # Configure in a separate build dir (VPATH build)
    cd "${build_dir}"
    CC="${cc}" CFLAGS="${cflags}" LDFLAGS="${cflags}" \
    "${SRC_DIR}/${SRC}/configure" \
        --host="${host}" \
        --prefix="${install_prefix}" \
        --enable-shared \
        --disable-static \
        --disable-docs
    make -j"$(sysctl -n hw.logicalcpu)"
    make install
}

log "[${PKG}] Building slices..."
for slice in ios-arm64 ios-arm64-simulator macos-arm64; do
    log "[${PKG}] Building ${slice}..."
    build_ffi_slice "${slice}"
done

log "[${PKG}] Assembling xcframework..."
for slice in ios-arm64 ios-arm64-simulator macos-arm64; do
    make_framework \
        "${FW_STAGING}/${slice}" "libffi" \
        "${INSTALL_BASE}/${slice}/lib/libffi.dylib" \
        "${INSTALL_BASE}/${slice}/include" \
        "$(slice_to_min_os "${slice}")" \
        "$(slice_to_platform "${slice}")"
done

make_xcframework "libffi" \
    "${FW_STAGING}/ios-arm64/libffi.framework" \
    "${FW_STAGING}/ios-arm64-simulator/libffi.framework" \
    "${FW_STAGING}/macos-arm64/libffi.framework"

log "[${PKG}] Done."
