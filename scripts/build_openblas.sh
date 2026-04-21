#!/bin/bash
# build_openblas.sh — builds OpenBLAS for ios-arm64, ios-arm64-simulator, macos-arm64
# and packages it as openblas.xcframework (no "lib" prefix — a-Shell drop-in compatible).
#
# NOTE: Uses Makefile build (NOT cmake).
# OpenBLAS cmake is "experimental" and generates the shared-lib link step as a
# hard-coded sh -c '$(CC) -fpic -shared ...' custom command that does NOT propagate
# CMAKE_OSX_SYSROOT / CMAKE_OSX_DEPLOYMENT_TARGET to the linker, causing the
# "building for macOS, but linking in iOS object" error on cross-compile slices.
# The Makefile build passes CC through to every compilation AND the dylib link step.
#
# PRD §7-7:
#   - iOS / Simulator slices: NOFORTRAN=1 is mandatory (no Fortran toolchain available).
#   - macOS slice: use gfortran from Homebrew gcc if present; fall back to NOFORTRAN=1.
#
# Each slice uses its own source copy to prevent OpenBLAS from writing generated
# files (config.h, Makefile_kernel) into the shared source tree.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=scripts/common.sh
source "${SCRIPT_DIR}/common.sh"
# shellcheck source=scripts/versions.sh
source "${SCRIPT_DIR}/versions.sh"

PKG="openblas"
VERSION="${OPENBLAS_VERSION}"
SRC="OpenBLAS-${VERSION}"
URL="https://github.com/OpenMathLib/OpenBLAS/releases/download/v${VERSION}/OpenBLAS-${VERSION}.tar.gz"
SHA256="f8a1138e01fddca9e4c29f9684fd570ba39dedc9ca76055e1425d5d4b1a4a766"

BUILD_BASE="${ROOT_DIR}/build/${PKG}"
INSTALL_BASE="${BUILD_BASE}/install"
FW_STAGING="${BUILD_BASE}/frameworks"
NCPU=$(sysctl -n hw.logicalcpu)

# ── Detect gfortran (macOS slice only) ────────────────────────────────────────
GFORTRAN=""
GCC_PREFIX="$(brew --prefix gcc 2>/dev/null || echo "")"
if [[ -n "${GCC_PREFIX}" ]]; then
    GFORTRAN="$(find "${GCC_PREFIX}/bin" -maxdepth 1 -name "gfortran-*" 2>/dev/null \
                | sort -V | tail -1 || echo "")"
fi
if [[ -n "${GFORTRAN}" ]]; then
    log "[${PKG}] Found gfortran: ${GFORTRAN} — macOS slice will use Fortran."
else
    log "[${PKG}] gfortran not found — macOS slice will use NOFORTRAN=1."
fi

log "[${PKG}] Fetching sources..."
fetch_source "${SRC}" "${URL}" "${SHA256}"

log "[${PKG}] Building slices..."
for slice in ios-arm64 ios-arm64-simulator macos-arm64; do
    src_copy="${BUILD_BASE}/src_${slice}"
    install_dir="${INSTALL_BASE}/${slice}"

    # Fresh per-slice source copy: OpenBLAS Makefile writes config.h and
    # Makefile_kernel into the source tree, causing cross-slice contamination.
    rm -rf "${src_copy}"
    mkdir -p "${src_copy}"
    rsync -a "${SRC_DIR}/${SRC}/" "${src_copy}/"

    case "${slice}" in
        ios-arm64)
            CC_TRIPLE="-arch arm64 -target arm64-apple-ios${IOS_MIN} -isysroot ${IOS_SDKROOT}"
            # CROSS_SUFFIX= / AR=ar / RANLIB=ranlib: OpenBLAS getarch.c parses CC to
            # auto-detect CROSS_SUFFIX, producing 'clang -arch ... /SDKs/' which then
            # prefixes ranlib/ar → broken tool invocations. Command-line vars override.
            # 'shared' target: build only the shared lib, skip test binaries.
            make -C "${src_copy}" shared \
                TARGET=ARMV8 \
                NOFORTRAN=1 \
                BUILD_WITHOUT_LAPACK=0 \
                CC="clang ${CC_TRIPLE}" \
                HOSTCC=clang \
                CROSS=1 \
                "CROSS_SUFFIX=" \
                AR=ar \
                RANLIB=ranlib \
                DYNAMIC_ARCH=0 \
                NO_SHARED=0 \
                PREFIX="${install_dir}" \
                -j${NCPU}
            make -C "${src_copy}" install PREFIX="${install_dir}"
            ;;
        ios-arm64-simulator)
            CC_TRIPLE="-arch arm64 -target arm64-apple-ios${IOS_MIN}-simulator -isysroot ${SIM_SDKROOT}"
            make -C "${src_copy}" shared \
                TARGET=ARMV8 \
                NOFORTRAN=1 \
                BUILD_WITHOUT_LAPACK=0 \
                CC="clang ${CC_TRIPLE}" \
                HOSTCC=clang \
                CROSS=1 \
                "CROSS_SUFFIX=" \
                AR=ar \
                RANLIB=ranlib \
                DYNAMIC_ARCH=0 \
                NO_SHARED=0 \
                PREFIX="${install_dir}" \
                -j${NCPU}
            make -C "${src_copy}" install PREFIX="${install_dir}"
            ;;
        macos-arm64)
            CC_TRIPLE="-arch arm64 -target arm64-apple-macos${MACOS_MIN} -isysroot ${OSX_SDKROOT}"
            if [[ -n "${GFORTRAN}" ]]; then
                # macOS native build: gfortran on M-series Mac targets arm64 macOS by
                # default — no -target flag (gfortran doesn't support -target).
                # CC (clang) carries the SDK flags for C code and the dylib link step.
                make -C "${src_copy}" shared \
                    TARGET=ARMV8 \
                    CC="clang ${CC_TRIPLE}" \
                    FC="${GFORTRAN}" \
                    HOSTCC=clang \
                    "CROSS_SUFFIX=" \
                    AR=ar \
                    RANLIB=ranlib \
                    DYNAMIC_ARCH=0 \
                    NO_SHARED=0 \
                    PREFIX="${install_dir}" \
                    -j${NCPU}
            else
                make -C "${src_copy}" shared \
                    TARGET=ARMV8 \
                    NOFORTRAN=1 \
                    BUILD_WITHOUT_LAPACK=0 \
                    CC="clang ${CC_TRIPLE}" \
                    HOSTCC=clang \
                    "CROSS_SUFFIX=" \
                    AR=ar \
                    RANLIB=ranlib \
                    DYNAMIC_ARCH=0 \
                    NO_SHARED=0 \
                    PREFIX="${install_dir}" \
                    -j${NCPU}
            fi
            make -C "${src_copy}" install PREFIX="${install_dir}"
            ;;
    esac
done

log "[${PKG}] Assembling xcframework..."
for slice in ios-arm64 ios-arm64-simulator macos-arm64; do
    make_framework \
        "${FW_STAGING}/${slice}" "openblas" \
        "${INSTALL_BASE}/${slice}/lib/libopenblas.dylib" \
        "${INSTALL_BASE}/${slice}/include" \
        "$(slice_to_min_os "${slice}")" \
        "$(slice_to_platform "${slice}")"
done

make_xcframework "openblas" \
    "${FW_STAGING}/ios-arm64/openblas.framework" \
    "${FW_STAGING}/ios-arm64-simulator/openblas.framework" \
    "${FW_STAGING}/macos-arm64/openblas.framework"

log "[${PKG}] Done."
