#!/usr/bin/env bash
set -euo pipefail

REPORT_DIR="${1:-hardware-report}"
ARCHIVE_PATH="${2:-hardware-report.tar.gz}"

mkdir -p "$REPORT_DIR"

if [[ $EUID -ne 0 ]]; then
  SUDO=(sudo)
else
  SUDO=()
fi

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

if command_exists inxi; then
  "${SUDO[@]}" inxi --full --admin --verbosity 8 > "$REPORT_DIR/overview.txt"
else
  echo "inxi is not installed; skipped overview report." > "$REPORT_DIR/overview.txt"
fi

if command_exists lshw; then
  "${SUDO[@]}" lshw -html > "$REPORT_DIR/hardware.html"
  "${SUDO[@]}" lshw -json > "$REPORT_DIR/hardware.json"
else
  echo "lshw is not installed; skipped HTML report." > "$REPORT_DIR/hardware.html"
  echo '{"warning":"lshw is not installed; skipped JSON report."}' > "$REPORT_DIR/hardware.json"
fi

if command_exists dmidecode; then
  "${SUDO[@]}" dmidecode > "$REPORT_DIR/dmidecode.txt"
else
  echo "dmidecode is not installed; skipped DMI report." > "$REPORT_DIR/dmidecode.txt"
fi

if command_exists lscpu; then
  lscpu > "$REPORT_DIR/cpu.txt"
else
  echo "lscpu is not installed; skipped CPU report." > "$REPORT_DIR/cpu.txt"
fi

if command_exists lspci; then
  lspci -nnk > "$REPORT_DIR/pci-devices.txt"
else
  echo "lspci is not installed; skipped PCI report." > "$REPORT_DIR/pci-devices.txt"
fi

if command_exists lsusb; then
  lsusb -v > "$REPORT_DIR/usb-devices.txt" 2>&1 || true
else
  echo "lsusb is not installed; skipped USB report." > "$REPORT_DIR/usb-devices.txt"
fi

if command_exists lsblk; then
  lsblk -O > "$REPORT_DIR/storage.txt"
else
  echo "lsblk is not installed; skipped storage report." > "$REPORT_DIR/storage.txt"
fi

{
  echo "=== COMPUTER ==="

  if command_exists dmidecode; then
    "${SUDO[@]}" dmidecode -t system \
      | grep -E 'Manufacturer:|Product Name:|Serial Number:|UUID:' || true
  else
    echo "dmidecode not installed"
  fi

  echo
  echo "=== CPU ==="

  if command_exists lscpu; then
    lscpu \
      | grep -E 'Model name:|CPU\(s\):|Core\(s\) per socket:|Thread\(s\) per core:' || true
  else
    echo "lscpu not installed"
  fi

  echo
  echo "=== MEMORY ==="

  if command_exists dmidecode; then
    "${SUDO[@]}" dmidecode -t memory \
      | awk '
        /^Memory Device$/ {
          in_device = 1
          size = ""
          block = ""
        }

        in_device {
          block = block $0 "\n"
        }

        in_device && /^[[:space:]]*Size:/ {
          size = $0
        }

        in_device && /^$/ {
          if (size !~ /No Module Installed/) {
            printf "%s", block
          }

          in_device = 0
        }

        END {
          if (in_device && size !~ /No Module Installed/) {
            printf "%s", block
          }
        }
      ' \
      | grep -E 'Locator:|Size:|Type:|Speed:|Manufacturer:|Serial Number:|Part Number:' || true
  else
    echo "dmidecode not installed"
  fi

  echo
  echo "=== STORAGE ==="

  if command_exists lsblk; then
    lsblk -d -o NAME,SIZE,MODEL,SERIAL,TRAN,VENDOR \
      | awk 'NR == 1 || $1 !~ /^(loop|ram|zram)/'
  else
    echo "lsblk not installed"
  fi

  echo
  echo "=== GPU / NETWORK ==="

  if command_exists lspci; then
    lspci \
      | grep -Ei 'vga|3d|display|ethernet|network' || true
  else
    echo "lspci not installed"
  fi
} > "$REPORT_DIR/inventory-summary.txt"

tar -czf "$ARCHIVE_PATH" "$REPORT_DIR"

printf 'Hardware report created: %s\n' "$REPORT_DIR"
printf 'Summary: %s/inventory-summary.txt\n' "$REPORT_DIR"
printf 'Archive: %s\n' "$ARCHIVE_PATH"
