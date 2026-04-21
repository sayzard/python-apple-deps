#!/bin/bash
# package_xcframeworks.sh — Package each xcframework into a zip and generate checksums
set -euo pipefail
trap 'echo "[ERROR] Line $LINENO: $BASH_COMMAND" >&2; exit 1' ERR

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
XCFW_DIR="${ROOT_DIR}/xcframeworks"

if [[ ! -d "${XCFW_DIR}" ]]; then
    echo "[ERROR] xcframeworks/ directory not found. Run ./build_all.sh first." >&2
    exit 1
fi

cd "${XCFW_DIR}"

FRAMEWORKS=(
    crypto
    freetype
    harfbuzz
    libexslt
    libffi
    libfftw3
    libfftw3_threads
    libgdal
    libgeos
    libgeos_c
    libheif
    libjpeg
    liblzma
    libpng
    libproj
    libspatialindex
    libspatialindex_c
    libtiff
    libxslt
    libz
    libzmq
    openblas
    openssl
)

CHECKSUMS_FILE="${ROOT_DIR}/checksums.sha256"
: > "${CHECKSUMS_FILE}"

for name in "${FRAMEWORKS[@]}"; do
    fw="${name}.xcframework"
    zip_file="${name}.xcframework.zip"

    if [[ ! -d "${fw}" ]]; then
        echo "[SKIP] ${fw} not found"
        continue
    fi

    echo "[ZIP] ${fw} → ${zip_file}"
    rm -f "${zip_file}"
    zip -qr "${zip_file}" "${fw}"

    checksum=$(shasum -a 256 "${zip_file}" | awk '{print $1}')
    echo "${checksum}  ${zip_file}" >> "${CHECKSUMS_FILE}"
    echo "      sha256: ${checksum}"
done

echo ""
echo "[DONE] Checksums written to checksums.sha256"
echo ""
echo "Update Package.swift URLs after uploading to GitHub Releases:"
echo "  https://github.com/sayzard/python-apple-deps/releases/download/TAG/<name>.xcframework.zip"
