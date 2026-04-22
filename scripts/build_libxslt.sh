#!/bin/bash
# build_libxslt.sh — builds libxslt (+ libexslt) for ios-arm64, ios-arm64-simulator, macos-arm64
# and packages two xcframeworks: libxslt and libexslt
#
# libxml2 is provided by the Apple SDK (no separate build required).
# We pass LIBXML_CFLAGS / LIBXML_LIBS directly and omit --with-libxml-src;
# that flag expects a libxml2 *source tree*, not a prefix, and would fail here.
#
# LDFLAGS mirrors CFLAGS (sysroot + arch) to prevent the linker from pulling in
# host-side libraries during cross-compilation.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=scripts/common.sh
source "${SCRIPT_DIR}/common.sh"
# shellcheck source=scripts/versions.sh
source "${SCRIPT_DIR}/versions.sh"

PKG="libxslt"
VERSION="${LIBXSLT_VERSION}"
SRC="libxslt-${VERSION}"
URL="https://download.gnome.org/sources/libxslt/1.1/libxslt-${VERSION}.tar.xz"
# Fill in after first download: shasum -a 256 libxslt-${VERSION}.tar.xz
SHA256="9acfe68419c4d06a45c550321b3212762d92f41465062ca4ea19e632ee5d216e"

BUILD_BASE="${ROOT_DIR}/build/${PKG}"
INSTALL_BASE="${BUILD_BASE}/install"
INSTALL_BASE_STATIC="${BUILD_BASE}/install_static"
FW_STAGING="${BUILD_BASE}/frameworks"

log "[${PKG}] Fetching sources..."
fetch_source "${SRC}" "${URL}" "${SHA256}"

# ── Per-slice autotools build ──────────────────────────────────────────────────
# build_xslt_slice <slice> <install_prefix> <build_dir> <shared_flag> <static_flag>
build_xslt_slice() {
    local slice="$1"
    local install_prefix="$2"
    local build_dir="$3"
    local shared_flag="$4"
    local static_flag="$5"

    log "[${PKG}] Building slice: ${slice} (${shared_flag}/${static_flag})"
    rm -rf "${build_dir}"
    mkdir -p "${build_dir}"

    local cc cflags host sysroot
    case "${slice}" in
        ios-arm64)
            sysroot="${IOS_SDKROOT}"
            cc="$(xcrun -sdk iphoneos -find clang)"
            host="aarch64-apple-darwin"
            cflags="-arch arm64 -target arm64-apple-ios${IOS_MIN} -isysroot ${sysroot}"
            ;;
        ios-arm64-simulator)
            sysroot="${SIM_SDKROOT}"
            cc="$(xcrun -sdk iphonesimulator -find clang)"
            host="aarch64-apple-darwin"
            cflags="-arch arm64 -target arm64-apple-ios${IOS_MIN}-simulator -isysroot ${sysroot}"
            ;;
        macos-arm64)
            sysroot="${OSX_SDKROOT}"
            cc="$(xcrun -sdk macosx -find clang)"
            host="aarch64-apple-darwin"
            cflags="-arch arm64 -target arm64-apple-macos${MACOS_MIN} -isysroot ${sysroot}"
            ;;
    esac

    local libxml_cflags="-I${sysroot}/usr/include/libxml2"
    local libxml_libs="-lxml2"

    (
        cd "${build_dir}"
        rsync -a "${SRC_DIR}/${SRC}/" .

        ./configure \
            --host="${host}" \
            --prefix="${install_prefix}" \
            "${shared_flag}" \
            "${static_flag}" \
            --without-python \
            --without-crypto \
            --without-debug \
            CC="${cc}" \
            CFLAGS="${cflags}" \
            LDFLAGS="${cflags}" \
            LIBXML_CFLAGS="${libxml_cflags}" \
            LIBXML_LIBS="${libxml_libs}"

        make -j"$(sysctl -n hw.logicalcpu)"
        make install
    )
}

log "[${PKG}] Building shared slices..."
for slice in ios-arm64 ios-arm64-simulator macos-arm64; do
    build_xslt_slice "${slice}" \
        "${INSTALL_BASE}/${slice}" \
        "${BUILD_BASE}/build_${slice}" \
        "--enable-shared" "--disable-static"
done

log "[${PKG}] Building static slices..."
for slice in ios-arm64 ios-arm64-simulator macos-arm64; do
    build_xslt_slice "${slice}" \
        "${INSTALL_BASE_STATIC}/${slice}" \
        "${BUILD_BASE}/build_static_${slice}" \
        "--disable-shared" "--enable-static"
done

# ── Assemble xcframeworks ─────────────────────────────────────────────────────
log "[${PKG}] Assembling xcframeworks..."
for slice in ios-arm64 ios-arm64-simulator macos-arm64; do
    local_min_os="$(slice_to_min_os "${slice}")"
    local_platform="$(slice_to_platform "${slice}")"

    make_framework \
        "${FW_STAGING}/${slice}" "libxslt" \
        "${INSTALL_BASE}/${slice}/lib/libxslt.dylib" \
        "${INSTALL_BASE}/${slice}/include" \
        "${local_min_os}" \
        "${local_platform}"
    add_static_lib \
        "${FW_STAGING}/${slice}" "libxslt" \
        "${INSTALL_BASE_STATIC}/${slice}/lib/libxslt.a"

    make_framework \
        "${FW_STAGING}/${slice}" "libexslt" \
        "${INSTALL_BASE}/${slice}/lib/libexslt.dylib" \
        "${INSTALL_BASE}/${slice}/include" \
        "${local_min_os}" \
        "${local_platform}"
    add_static_lib \
        "${FW_STAGING}/${slice}" "libexslt" \
        "${INSTALL_BASE_STATIC}/${slice}/lib/libexslt.a"

    # Rewrite embedded libxslt dependency inside libexslt to @rpath
    rewrite_dep \
        "${FW_STAGING}/${slice}/libexslt.framework/libexslt" \
        "libxslt" \
        "libxslt"
done

make_xcframework "libxslt" \
    "${FW_STAGING}/ios-arm64/libxslt.framework" \
    "${FW_STAGING}/ios-arm64-simulator/libxslt.framework" \
    "${FW_STAGING}/macos-arm64/libxslt.framework"

make_xcframework "libexslt" \
    "${FW_STAGING}/ios-arm64/libexslt.framework" \
    "${FW_STAGING}/ios-arm64-simulator/libexslt.framework" \
    "${FW_STAGING}/macos-arm64/libexslt.framework"

log "[${PKG}] Done."
