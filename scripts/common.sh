#!/bin/bash
# common.sh — 모든 빌드 스크립트가 source 하는 공통 함수 모음
set -euo pipefail
trap 'echo "[ERROR] Line $LINENO: $BASH_COMMAND" >&2; exit 1' ERR

# ── 경로 설정 ────────────────────────────────────────────────────────────────
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_DIR="${ROOT_DIR}/src"
XCFW_OUT="${ROOT_DIR}/xcframeworks"
mkdir -p "${SRC_DIR}" "${XCFW_OUT}"

# ── SDK 경로 ─────────────────────────────────────────────────────────────────
IOS_SDKROOT=$(xcrun --sdk iphoneos          --show-sdk-path)
SIM_SDKROOT=$(xcrun --sdk iphonesimulator   --show-sdk-path)
OSX_SDKROOT=$(xcrun --sdk macosx            --show-sdk-path)

# ── 최소 배포 타겟 ────────────────────────────────────────────────────────────
IOS_MIN=16.0
MACOS_MIN=13.0

# ── cmake 공통 플래그 ─────────────────────────────────────────────────────────
# NO_PACKAGE_REGISTRY: cmake user registry (~/.cmake/packages/) 오염 방지.
# OpenBLAS처럼 export(PACKAGE ...) 를 호출하는 패키지가 앞 슬라이스 빌드 결과를
# 뒤 슬라이스 cmake configure 시 find_package로 집어오는 크로스-슬라이스 오염을 막는다.
CMAKE_COMMON="-DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON -DCMAKE_EXPORT_NO_PACKAGE_REGISTRY=ON -DCMAKE_FIND_PACKAGE_NO_PACKAGE_REGISTRY=ON"

# ── 슬라이스 → 플랫폼/최소OS 매핑 ───────────────────────────────────────────
slice_to_platform() {
    case "$1" in
        ios-arm64)              echo "iPhoneOS" ;;
        ios-arm64-simulator)    echo "iPhoneSimulator" ;;
        macos-arm64)            echo "MacOSX" ;;
    esac
}

slice_to_min_os() {
    case "$1" in
        ios-arm64|ios-arm64-simulator)  echo "${IOS_MIN}" ;;
        macos-arm64)                    echo "${MACOS_MIN}" ;;
    esac
}

# ── 소스 다운로드 + sha256 검증 ───────────────────────────────────────────────
# fetch_source <dir-name> <url> <expected-sha256 or "">
fetch_source() {
    local dir_name="$1"
    local url="$2"
    local expected_sha256="${3:-}"
    local tarball
    tarball="$(basename "${url}")"
    local tarball_path="${SRC_DIR}/${tarball}"
    local src_path="${SRC_DIR}/${dir_name}"

    if [[ -d "${src_path}" ]]; then
        echo "[SKIP] ${dir_name} already extracted"
        return 0
    fi

    if [[ ! -f "${tarball_path}" ]]; then
        echo "[FETCH] ${url}"
        curl -fL --retry 3 --retry-delay 5 -o "${tarball_path}" "${url}"
    fi

    if [[ -n "${expected_sha256}" ]]; then
        local actual
        actual=$(shasum -a 256 "${tarball_path}" | awk '{print $1}')
        if [[ "${actual}" != "${expected_sha256}" ]]; then
            echo "[ERROR] SHA256 mismatch for ${tarball}" >&2
            echo "  expected: ${expected_sha256}" >&2
            echo "  actual:   ${actual}" >&2
            rm -f "${tarball_path}"
            exit 1
        fi
    fi

    echo "[EXTRACT] ${tarball}"
    tar -xf "${tarball_path}" -C "${SRC_DIR}"
}

# ── cmake 슬라이스 빌드 ───────────────────────────────────────────────────────
# cmake_build_slice <slice> <src_dir> <cmake_build_dir> <install_prefix> [extra cmake flags...]
cmake_build_slice() {
    local slice="$1"
    local src_dir="$2"
    local cmake_build_dir="$3"
    local install_prefix="$4"
    shift 4
    local extra_flags=("$@")

    local sysroot min_os system_flag=""
    case "${slice}" in
        ios-arm64)
            sysroot="${IOS_SDKROOT}"; min_os="${IOS_MIN}"
            system_flag="-DCMAKE_SYSTEM_NAME=iOS"
            ;;
        ios-arm64-simulator)
            sysroot="${SIM_SDKROOT}"; min_os="${IOS_MIN}"
            system_flag="-DCMAKE_SYSTEM_NAME=iOS"
            ;;
        macos-arm64)
            sysroot="${OSX_SDKROOT}"; min_os="${MACOS_MIN}"
            ;;
    esac

    rm -rf "${cmake_build_dir}"
    mkdir -p "${cmake_build_dir}"

    # shellcheck disable=SC2086
    cmake -S "${src_dir}" -B "${cmake_build_dir}" \
        ${CMAKE_COMMON} \
        ${system_flag} \
        -DCMAKE_OSX_SYSROOT="${sysroot}" \
        -DCMAKE_OSX_ARCHITECTURES=arm64 \
        -DCMAKE_OSX_DEPLOYMENT_TARGET="${min_os}" \
        -DCMAKE_INSTALL_PREFIX="${install_prefix}" \
        "${extra_flags[@]}"
    cmake --build "${cmake_build_dir}" --parallel "$(sysctl -n hw.logicalcpu)"
    cmake --install "${cmake_build_dir}"
}

# ── .framework 번들 조립 ──────────────────────────────────────────────────────
# make_framework <out_dir> <name> <dylib_path> <headers_dir> <min_os> <platform>
make_framework() {
    local out_dir="$1"
    local name="$2"
    local dylib_path="$3"
    local headers_dir="$4"
    local min_os="$5"
    local platform="$6"

    local fw_dir="${out_dir}/${name}.framework"
    rm -rf "${fw_dir}"
    mkdir -p "${fw_dir}/Headers"

    # 심볼릭 링크 해제하여 실제 dylib 복사
    cp -L "${dylib_path}" "${fw_dir}/${name}"

    # 헤더 복사
    if [[ -d "${headers_dir}" ]]; then
        cp -R "${headers_dir}/." "${fw_dir}/Headers/"
    fi

    # Info.plist 주입
    sed -e "s|@NAME@|${name}|g" \
        -e "s|@MIN_OS@|${min_os}|g" \
        -e "s|@PLATFORM@|${platform}|g" \
        "${ROOT_DIR}/Info.plist.template" > "${fw_dir}/Info.plist"

    # install_name 고정
    install_name_tool -id "@rpath/${name}.framework/${name}" "${fw_dir}/${name}"
}

# ── LC_LOAD_DYLIB 재작성 ─────────────────────────────────────────────────────
# rewrite_dep <binary> <old_pattern> <new_rpath_name>
rewrite_dep() {
    local binary="$1"
    local old_pattern="$2"
    local new_rpath_name="$3"
    local old_name
    # Skip line 1 (file header "binary:") and line 2 (LC_ID_DYLIB / self install_name)
    # to avoid accidentally matching the binary's own name.
    old_name=$(otool -L "${binary}" | tail -n +3 | awk '{print $1}' \
        | grep -F "${old_pattern}" | head -1 || true)
    if [[ -n "${old_name}" ]]; then
        install_name_tool -change "${old_name}" \
            "@rpath/${new_rpath_name}.framework/${new_rpath_name}" "${binary}"
    fi
}

# ── xcframework 생성 ─────────────────────────────────────────────────────────
# make_xcframework <name> <ios_fw_dir> <sim_fw_dir> <osx_fw_dir>
make_xcframework() {
    local name="$1"
    local ios_fw="$2"
    local sim_fw="$3"
    local osx_fw="$4"
    local output="${XCFW_OUT}/${name}.xcframework"

    rm -rf "${output}"
    xcodebuild -create-xcframework \
        -framework "${ios_fw}" \
        -framework "${sim_fw}" \
        -framework "${osx_fw}" \
        -output "${output}"
    echo "[OK] ${output}"
}

log() {
    echo "[$(date '+%H:%M:%S')] $*"
}
