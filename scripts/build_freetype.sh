#!/bin/bash
# build_freetype.sh — builds FreeType and HarfBuzz for ios-arm64, ios-arm64-simulator, macos-arm64
# and packages two xcframeworks: freetype and harfbuzz (no "lib" prefix).
#
# Build order:
#   Stage 1 — FreeType (all 3 slices) without HarfBuzz
#   Stage 2 — HarfBuzz (all 3 slices) with FreeType from Stage 1
#
# A third-stage FreeType rebuild with HarfBuzz support is intentionally omitted
# to keep the build graph acyclic; this is sufficient for Python extension use.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=scripts/common.sh
source "${SCRIPT_DIR}/common.sh"
# shellcheck source=scripts/versions.sh
source "${SCRIPT_DIR}/versions.sh"

# ── FreeType ──────────────────────────────────────────────────────────────────
FT_PKG="freetype"
FT_VERSION="${FREETYPE_VERSION}"
FT_SRC="freetype-${FT_VERSION}"
FT_URL="https://download.savannah.gnu.org/releases/freetype/freetype-${FT_VERSION}.tar.gz"
# Fill in after first download: shasum -a 256 freetype-${FT_VERSION}.tar.gz
FT_SHA256="752c2671f85c54a84b7f0dd2b5cd26b6b741117033886ffbc5ac89a68464b848"

FT_BUILD_BASE="${ROOT_DIR}/build/${FT_PKG}"
FT_INSTALL_BASE="${FT_BUILD_BASE}/install"
FT_FW_STAGING="${FT_BUILD_BASE}/frameworks"

# ── HarfBuzz ──────────────────────────────────────────────────────────────────
HB_PKG="harfbuzz"
HB_VERSION="${HARFBUZZ_VERSION}"
HB_SRC="harfbuzz-${HB_VERSION}"
HB_URL="https://github.com/harfbuzz/harfbuzz/releases/download/${HB_VERSION}/harfbuzz-${HB_VERSION}.tar.xz"
# Fill in after first download: shasum -a 256 harfbuzz-${HB_VERSION}.tar.xz
HB_SHA256="480b6d25014169300669aa1fc39fb356c142d5028324ea52b3a27648b9beaad8"

HB_BUILD_BASE="${ROOT_DIR}/build/${HB_PKG}"
HB_INSTALL_BASE="${HB_BUILD_BASE}/install"
HB_FW_STAGING="${HB_BUILD_BASE}/frameworks"

# ── Stage 1: FreeType (no HarfBuzz) ──────────────────────────────────────────
log "[${FT_PKG}] Fetching sources..."
fetch_source "${FT_SRC}" "${FT_URL}" "${FT_SHA256}"

log "[${FT_PKG}] Building slices (without HarfBuzz)..."
for slice in ios-arm64 ios-arm64-simulator macos-arm64; do
    cmake_build_slice "${slice}" \
        "${SRC_DIR}/${FT_SRC}" \
        "${FT_BUILD_BASE}/cmake_${slice}" \
        "${FT_INSTALL_BASE}/${slice}" \
        -DFT_DISABLE_HARFBUZZ=TRUE \
        -DFT_DISABLE_BZIP2=TRUE \
        -DFT_DISABLE_BROTLI=TRUE
done

# ── Stage 2: HarfBuzz (with FreeType) ────────────────────────────────────────
log "[${HB_PKG}] Fetching sources..."
fetch_source "${HB_SRC}" "${HB_URL}" "${HB_SHA256}"

log "[${HB_PKG}] Building slices (with FreeType)..."
for slice in ios-arm64 ios-arm64-simulator macos-arm64; do
    cmake_build_slice "${slice}" \
        "${SRC_DIR}/${HB_SRC}" \
        "${HB_BUILD_BASE}/cmake_${slice}" \
        "${HB_INSTALL_BASE}/${slice}" \
        -DHB_BUILD_TESTS=OFF \
        -DHB_BUILD_UTILS=OFF \
        -DHB_HAVE_FREETYPE=ON \
        -DHB_HAVE_CORETEXT=OFF \
        -DFREETYPE_INCLUDE_DIRS="${FT_INSTALL_BASE}/${slice}/include/freetype2" \
        -DFREETYPE_LIBRARY="${FT_INSTALL_BASE}/${slice}/lib/libfreetype.dylib"
done

# ── Assemble xcframeworks ─────────────────────────────────────────────────────
log "[${FT_PKG}] Assembling xcframework..."
for slice in ios-arm64 ios-arm64-simulator macos-arm64; do
    make_framework \
        "${FT_FW_STAGING}/${slice}" "freetype" \
        "${FT_INSTALL_BASE}/${slice}/lib/libfreetype.dylib" \
        "${FT_INSTALL_BASE}/${slice}/include" \
        "$(slice_to_min_os "${slice}")" \
        "$(slice_to_platform "${slice}")"
done

# xcframework name is "freetype" (no "lib" prefix)
make_xcframework "freetype" \
    "${FT_FW_STAGING}/ios-arm64/freetype.framework" \
    "${FT_FW_STAGING}/ios-arm64-simulator/freetype.framework" \
    "${FT_FW_STAGING}/macos-arm64/freetype.framework"

log "[${HB_PKG}] Assembling xcframework..."
for slice in ios-arm64 ios-arm64-simulator macos-arm64; do
    make_framework \
        "${HB_FW_STAGING}/${slice}" "harfbuzz" \
        "${HB_INSTALL_BASE}/${slice}/lib/libharfbuzz.dylib" \
        "${HB_INSTALL_BASE}/${slice}/include" \
        "$(slice_to_min_os "${slice}")" \
        "$(slice_to_platform "${slice}")"

    # Rewrite embedded libfreetype dependency to @rpath
    rewrite_dep \
        "${HB_FW_STAGING}/${slice}/harfbuzz.framework/harfbuzz" \
        "libfreetype" \
        "freetype"
done

# xcframework name is "harfbuzz" (no "lib" prefix)
make_xcframework "harfbuzz" \
    "${HB_FW_STAGING}/ios-arm64/harfbuzz.framework" \
    "${HB_FW_STAGING}/ios-arm64-simulator/harfbuzz.framework" \
    "${HB_FW_STAGING}/macos-arm64/harfbuzz.framework"

log "[freetype+harfbuzz] Done."
