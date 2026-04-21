#!/bin/bash
# build_all.sh — PRD §8 의존성 순서대로 전체 빌드
set -euo pipefail
trap 'echo "[ERROR] Line $LINENO: $BASH_COMMAND" >&2; exit 1' ERR

SCRIPTS="$(cd "$(dirname "$0")/scripts" && pwd)"

log() { echo "[$(date '+%H:%M:%S')] $*"; }

log "=== Python-aux build started ==="
log "Host: $(sw_vers -productVersion), Xcode: $(xcodebuild -version | head -1)"
log "cmake: $(cmake --version | head -1)"

log " 1/17  openssl"         ; bash "${SCRIPTS}/build_openssl.sh"
log " 2/17  liblzma"         ; bash "${SCRIPTS}/build_liblzma.sh"
log " 3/17  zlib"            ; bash "${SCRIPTS}/build_zlib.sh"
log " 4/17  libffi"          ; bash "${SCRIPTS}/build_libffi.sh"
log " 5/17  libjpeg-turbo"   ; bash "${SCRIPTS}/build_libjpeg_turbo.sh"
log " 6/17  libpng"          ; bash "${SCRIPTS}/build_libpng.sh"
log " 7/17  libtiff"         ; bash "${SCRIPTS}/build_libtiff.sh"
log " 8/17  libheif"         ; bash "${SCRIPTS}/build_libheif.sh"
log " 9/17  freetype+harfbuzz"; bash "${SCRIPTS}/build_freetype.sh"
log "10/17  libzmq"          ; bash "${SCRIPTS}/build_libzmq.sh"
log "11/17  libxslt"         ; bash "${SCRIPTS}/build_libxslt.sh"
log "12/17  fftw"            ; bash "${SCRIPTS}/build_fftw.sh"
log "13/17  openblas"        ; bash "${SCRIPTS}/build_openblas.sh"
log "14/17  geos"            ; bash "${SCRIPTS}/build_geos.sh"
log "15/17  proj"            ; bash "${SCRIPTS}/build_proj.sh"
log "16/17  gdal"            ; bash "${SCRIPTS}/build_gdal.sh"
log "17/17  libspatialindex" ; bash "${SCRIPTS}/build_libspatialindex.sh"

log "=== All builds complete. xcframeworks → $(pwd)/xcframeworks/ ==="
