#!/usr/bin/env bash
set -euo pipefail

REPORT_DIR="${1:-hardware-report}"
SUMMARY_FILE="$REPORT_DIR/inventory-summary.txt"
ARCHIVE_PATH="${2:-hardware-report.tar.gz}"

required_files=(
  "overview.txt"
  "hardware.html"
  "hardware.json"
  "dmidecode.txt"
  "cpu.txt"
  "pci-devices.txt"
  "usb-devices.txt"
  "storage.txt"
  "inventory-summary.txt"
)

status=0

if [[ ! -d "$REPORT_DIR" ]]; then
  printf 'ERROR: Report directory does not exist: %s\n' "$REPORT_DIR" >&2
  exit 1
fi

for file in "${required_files[@]}"; do
  path="$REPORT_DIR/$file"

  if [[ ! -s "$path" ]]; then
    printf 'ERROR: Missing or empty file: %s\n' "$path" >&2
    status=1
  else
    printf 'OK: %s\n' "$path"
  fi
done

if [[ ! -s "$ARCHIVE_PATH" ]]; then
  printf 'WARNING: Archive missing or empty: %s\n' "$ARCHIVE_PATH" >&2
else
  printf 'OK: %s\n' "$ARCHIVE_PATH"
fi

if [[ -s "$SUMMARY_FILE" ]]; then
  printf '\nSummary checks:\n'

  for section in '=== COMPUTER ===' '=== CPU ===' '=== MEMORY ===' '=== STORAGE ===' '=== GPU / NETWORK ==='; do
    if grep -Fq "$section" "$SUMMARY_FILE"; then
      printf 'OK: %s\n' "$section"
    else
      printf 'ERROR: Missing section: %s\n' "$section" >&2
      status=1
    fi
  done

  if grep -Eq '^[[:space:]]*Serial Number: .+' "$SUMMARY_FILE"; then
    printf 'OK: System serial number found\n'
  else
    printf 'WARNING: No system serial number found\n' >&2
  fi

  if grep -Eq '^[[:space:]]*Model name: .+' "$SUMMARY_FILE"; then
    printf 'OK: CPU model found\n'
  else
    printf 'ERROR: No CPU model found\n' >&2
    status=1
  fi

  if grep -Eq '^NAME[[:space:]]+SIZE' "$SUMMARY_FILE"; then
    printf 'OK: Storage table found\n'
  else
    printf 'ERROR: Storage table missing\n' >&2
    status=1
  fi
fi

if [[ $status -eq 0 ]]; then
  printf '\nHardware report check passed.\n'
else
  printf '\nHardware report check failed. Review the errors above.\n' >&2
fi

exit "$status"
