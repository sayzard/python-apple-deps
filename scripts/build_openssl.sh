#!/bin/bash
# build_openssl.sh — builds OpenSSL (static) for ios-arm64, ios-arm64-simulator, macos-arm64
# and packages two xcframeworks: openssl and crypto (no "lib" prefix).
#
# OpenSSL uses its own ./Configure system; cmake is not supported.
# Built as static libraries (no-shared) — xcframeworks use -library (not -framework).
#
# Approach: use `export SDKROOT` for all three slices — modern OpenSSL ./Configure
# honours SDKROOT for both ios64-xcrun and iossimulator-xcrun targets, which is
# cleaner than the legacy CROSS_TOP/CROSS_SDK approach.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=scripts/common.sh
source "${SCRIPT_DIR}/common.sh"
# shellcheck source=scripts/versions.sh
source "${SCRIPT_DIR}/versions.sh"

PKG="openssl"
VERSION="${OPENSSL_VERSION}"
SRC="openssl-${VERSION}"
URL="https://www.openssl.org/source/openssl-${VERSION}.tar.gz"
# Fill in after first download: shasum -a 256 openssl-${VERSION}.tar.gz
SHA256="002a2d6b30b58bf4bea46c43bdd96365aaf8daa6c428782aa4feee06da197df3"

BUILD_BASE="${ROOT_DIR}/build/${PKG}"
INSTALL_BASE="${BUILD_BASE}/install"

log "[${PKG}] Fetching sources..."
fetch_source "${SRC}" "${URL}" "${SHA256}"

# ── Per-slice build ────────────────────────────────────────────────────────────
build_openssl_slice() {
    local slice="$1"
    local install_prefix="${INSTALL_BASE}/${slice}"
    local build_dir="${BUILD_BASE}/build_${slice}"

    log "[${PKG}] Building slice: ${slice}"
    rm -rf "${build_dir}"
    mkdir -p "${build_dir}"

    # Copy source tree so Configure + make run in isolation
    rsync -a "${SRC_DIR}/${SRC}/" "${build_dir}/"

    local target platform_flags
    case "${slice}" in
        ios-arm64)
            export SDKROOT="${IOS_SDKROOT}"
            target="ios64-xcrun"
            platform_flags="no-async enable-ec_nistp_64_gcc_128"
            ;;
        ios-arm64-simulator)
            export SDKROOT="${SIM_SDKROOT}"
            target="iossimulator-xcrun"
            platform_flags="no-async"
            ;;
        macos-arm64)
            export SDKROOT="${OSX_SDKROOT}"
            target="darwin64-arm64-cc"
            platform_flags=""
            ;;
    esac

    (
        cd "${build_dir}"
        # shellcheck disable=SC2086
        ./Configure "${target}" \
            --prefix="${install_prefix}" \
            no-shared no-dso no-engine no-tests \
            ${platform_flags}
        make -j"$(sysctl -n hw.logicalcpu)"
        make install_sw   # installs headers + static libs only (no man pages)
    )

    unset SDKROOT
}

for slice in ios-arm64 ios-arm64-simulator macos-arm64; do
    build_openssl_slice "${slice}"
done

# ── Assemble xcframeworks (static -library mode) ──────────────────────────────
# make_xcframework only supports -framework; call xcodebuild directly here.
log "[${PKG}] Assembling xcframeworks (static library mode)..."

rm -rf "${XCFW_OUT}/openssl.xcframework"
xcodebuild -create-xcframework \
    -library "${INSTALL_BASE}/ios-arm64/lib/libssl.a" \
    -headers "${INSTALL_BASE}/ios-arm64/include" \
    -library "${INSTALL_BASE}/ios-arm64-simulator/lib/libssl.a" \
    -headers "${INSTALL_BASE}/ios-arm64-simulator/include" \
    -library "${INSTALL_BASE}/macos-arm64/lib/libssl.a" \
    -headers "${INSTALL_BASE}/macos-arm64/include" \
    -output "${XCFW_OUT}/openssl.xcframework"
echo "[OK] ${XCFW_OUT}/openssl.xcframework"

rm -rf "${XCFW_OUT}/crypto.xcframework"
xcodebuild -create-xcframework \
    -library "${INSTALL_BASE}/ios-arm64/lib/libcrypto.a" \
    -headers "${INSTALL_BASE}/ios-arm64/include" \
    -library "${INSTALL_BASE}/ios-arm64-simulator/lib/libcrypto.a" \
    -headers "${INSTALL_BASE}/ios-arm64-simulator/include" \
    -library "${INSTALL_BASE}/macos-arm64/lib/libcrypto.a" \
    -headers "${INSTALL_BASE}/macos-arm64/include" \
    -output "${XCFW_OUT}/crypto.xcframework"
echo "[OK] ${XCFW_OUT}/crypto.xcframework"

log "[${PKG}] Done."
