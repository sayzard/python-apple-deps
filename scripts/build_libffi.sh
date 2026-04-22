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
INSTALL_BASE_STATIC="${BUILD_BASE}/install_static"
FW_STAGING="${BUILD_BASE}/frameworks"

log "[${PKG}] Fetching sources..."
fetch_source "${SRC}" "${URL}" "${SHA256}"

build_ffi_slice() {
    local slice="$1"
    local install_prefix="$2"
    local build_dir="$3"
    local shared_flag="$4"
    local static_flag="$5"

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

    cd "${build_dir}"
    CC="${cc}" CFLAGS="${cflags}" LDFLAGS="${cflags}" \
    "${SRC_DIR}/${SRC}/configure" \
        --host="${host}" \
        --prefix="${install_prefix}" \
        "${shared_flag}" \
        "${static_flag}" \
        --disable-docs
    make -j"$(sysctl -n hw.logicalcpu)"
    make install
}

log "[${PKG}] Building shared slices..."
for slice in ios-arm64 ios-arm64-simulator macos-arm64; do
    log "[${PKG}] Building shared ${slice}..."
    build_ffi_slice "${slice}" \
        "${INSTALL_BASE}/${slice}" \
        "${BUILD_BASE}/build_${slice}" \
        "--enable-shared" "--disable-static"
done

log "[${PKG}] Building static slices..."
for slice in ios-arm64 ios-arm64-simulator macos-arm64; do
    log "[${PKG}] Building static ${slice}..."
    build_ffi_slice "${slice}" \
        "${INSTALL_BASE_STATIC}/${slice}" \
        "${BUILD_BASE}/build_static_${slice}" \
        "--disable-shared" "--enable-static"
done

log "[${PKG}] Assembling xcframework..."
for slice in ios-arm64 ios-arm64-simulator macos-arm64; do
    make_framework \
        "${FW_STAGING}/${slice}" "libffi" \
        "${INSTALL_BASE}/${slice}/lib/libffi.dylib" \
        "${INSTALL_BASE}/${slice}/include" \
        "$(slice_to_min_os "${slice}")" \
        "$(slice_to_platform "${slice}")"
    add_static_lib \
        "${FW_STAGING}/${slice}" "libffi" \
        "${INSTALL_BASE_STATIC}/${slice}/lib/libffi.a"
done

make_xcframework "libffi" \
    "${FW_STAGING}/ios-arm64/libffi.framework" \
    "${FW_STAGING}/ios-arm64-simulator/libffi.framework" \
    "${FW_STAGING}/macos-arm64/libffi.framework"

log "[${PKG}] Done."
