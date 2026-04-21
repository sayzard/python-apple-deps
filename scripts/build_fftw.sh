#!/bin/bash
# build_fftw.sh — builds FFTW3 (double precision, with threads) for
# ios-arm64, ios-arm64-simulator, macos-arm64
# and packages two xcframeworks: libfftw3 and libfftw3_threads
#
# FFTW uses autotools (./configure --host); single-precision (fftwf) is omitted.
# LDFLAGS mirrors CFLAGS sysroot/arch so the linker picks up SDK libs, not host libs.
# NOTE: autotools cross-compile may trigger AC_RUN_IFELSE failures on some configure
# checks (the built test binary cannot run on the macOS host). If configure aborts,
# cached answers can be injected via additional env vars (e.g. ac_cv_func_malloc_0_nonnull=yes).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=scripts/common.sh
source "${SCRIPT_DIR}/common.sh"
# shellcheck source=scripts/versions.sh
source "${SCRIPT_DIR}/versions.sh"

PKG="fftw"
VERSION="${FFTW_VERSION}"
SRC="fftw-${VERSION}"
URL="https://fftw.org/fftw-${VERSION}.tar.gz"
# Fill in after first download: shasum -a 256 fftw-${VERSION}.tar.gz
SHA256="56c932549852cddcfafdab3820b0200c7742675be92179e59e6215b340e26467"

BUILD_BASE="${ROOT_DIR}/build/${PKG}"
INSTALL_BASE="${BUILD_BASE}/install"
FW_STAGING="${BUILD_BASE}/frameworks"

log "[${PKG}] Fetching sources..."
fetch_source "${SRC}" "${URL}" "${SHA256}"

# ── Per-slice autotools build ──────────────────────────────────────────────────
build_fftw_slice() {
    local slice="$1"
    local install_prefix="${INSTALL_BASE}/${slice}"
    local build_dir="${BUILD_BASE}/build_${slice}"

    log "[${PKG}] Building slice: ${slice}"
    rm -rf "${build_dir}"
    mkdir -p "${build_dir}"

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

    (
        cd "${build_dir}"
        # Run configure from build dir against unpacked source
        "${SRC_DIR}/${SRC}/configure" \
            --host="${host}" \
            --prefix="${install_prefix}" \
            --enable-shared \
            --disable-static \
            --enable-threads \
            --disable-fortran \
            CC="${cc}" \
            CFLAGS="${cflags}" \
            LDFLAGS="${cflags}"   # LDFLAGS must mirror CFLAGS for correct sysroot/arch
        make -j"$(sysctl -n hw.logicalcpu)"
        make install
    )
}

for slice in ios-arm64 ios-arm64-simulator macos-arm64; do
    build_fftw_slice "${slice}"
done

# ── Assemble xcframeworks ─────────────────────────────────────────────────────
log "[${PKG}] Assembling xcframeworks..."
for slice in ios-arm64 ios-arm64-simulator macos-arm64; do
    local_min_os="$(slice_to_min_os "${slice}")"
    local_platform="$(slice_to_platform "${slice}")"

    make_framework \
        "${FW_STAGING}/${slice}" "libfftw3" \
        "${INSTALL_BASE}/${slice}/lib/libfftw3.dylib" \
        "${INSTALL_BASE}/${slice}/include" \
        "${local_min_os}" \
        "${local_platform}"

    make_framework \
        "${FW_STAGING}/${slice}" "libfftw3_threads" \
        "${INSTALL_BASE}/${slice}/lib/libfftw3_threads.dylib" \
        "${INSTALL_BASE}/${slice}/include" \
        "${local_min_os}" \
        "${local_platform}"
done

make_xcframework "libfftw3" \
    "${FW_STAGING}/ios-arm64/libfftw3.framework" \
    "${FW_STAGING}/ios-arm64-simulator/libfftw3.framework" \
    "${FW_STAGING}/macos-arm64/libfftw3.framework"

make_xcframework "libfftw3_threads" \
    "${FW_STAGING}/ios-arm64/libfftw3_threads.framework" \
    "${FW_STAGING}/ios-arm64-simulator/libfftw3_threads.framework" \
    "${FW_STAGING}/macos-arm64/libfftw3_threads.framework"

log "[${PKG}] Done."
