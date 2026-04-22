#!/bin/bash
# tests/verify_xcframework.sh — Full xcframework validation
# Handles both dynamic (.framework) and static (-library) xcframework formats.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
XCFW_DIR="${ROOT_DIR}/xcframeworks"
PASS=0
FAIL=0

red()   { echo -e "\033[31m$*\033[0m"; }
green() { echo -e "\033[32m$*\033[0m"; }

check() {
    local desc="$1"; shift
    if "$@" &>/dev/null; then
        green "  [PASS] ${desc}"
        PASS=$((PASS + 1))
    else
        red   "  [FAIL] ${desc}"
        FAIL=$((FAIL + 1))
    fi
}

for fw_path in "${XCFW_DIR}"/*.xcframework; do
    [[ -d "${fw_path}" ]] || continue
    fw_name=$(basename "${fw_path}" .xcframework)
    echo ""
    echo "▶ ${fw_name}.xcframework"

    # Detect format by looking at ios-arm64 slice
    if [[ -d "${fw_path}/ios-arm64/${fw_name}.framework" ]]; then
        fmt="dynamic"
    else
        fmt="static"
    fi
    echo "  format: ${fmt}"

    for slice in ios-arm64 ios-arm64-simulator macos-arm64; do
        if [[ "${fmt}" == "dynamic" ]]; then
            binary="${fw_path}/${slice}/${fw_name}.framework/${fw_name}"
            plist="${fw_path}/${slice}/${fw_name}.framework/Info.plist"
            static_lib="${fw_path}/${slice}/${fw_name}.framework/${fw_name}.a"

            check "${slice}: binary exists"      test -f "${binary}"
            check "${slice}: Info.plist exists"  test -f "${plist}"

            if [[ -f "${binary}" ]]; then
                check "${slice}: arm64 arch" \
                    bash -c "file '${binary}' | grep -q arm64"
                expected_id="@rpath/${fw_name}.framework/${fw_name}"
                check "${slice}: install_name = ${expected_id}" \
                    bash -c "[[ \"\$(otool -D '${binary}' | tail -1)\" == '${expected_id}' ]]"
            fi
            if [[ -f "${plist}" ]]; then
                check "${slice}: Info.plist valid" \
                    plutil -lint "${plist}"
                check "${slice}: CFBundleExecutable = ${fw_name}" \
                    bash -c "[[ \"\$(plutil -extract CFBundleExecutable raw '${plist}')\" == '${fw_name}' ]]"
            fi
            # Static companion (.a) — present only for libraries that have a static build
            if [[ -f "${static_lib}" ]]; then
                check "${slice}: static .a arm64 arch" \
                    bash -c "lipo -info '${static_lib}' | grep -q arm64"
            fi
        else
            # Static library format: any .a in the slice directory
            lib_path=$(find "${fw_path}/${slice}" -maxdepth 1 -name "*.a" | head -1)
            check "${slice}: static lib exists" test -n "${lib_path}"
            if [[ -n "${lib_path}" ]]; then
                check "${slice}: arm64 arch" \
                    bash -c "lipo -info '${lib_path}' | grep -q arm64"
            fi
            check "${slice}: Headers dir exists" test -d "${fw_path}/${slice}/Headers"
        fi
    done
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Results: ${PASS} passed, ${FAIL} failed"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

[[ ${FAIL} -eq 0 ]]
