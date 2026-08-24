(MANUAL)
WHEN USING GENERATE HARDWARE REPORT.SH AFTER THAT USE CHECK-HARDWARE-REPORT.SH IMMEDIATLY
SO FIRST USE generate-hardware-report.sh AND THEN USE check-hardware-report.sh

FOR AUTOMATIC LIVE USB USAGE:
put ubuntu live usb in target
boot the ubuntu server usb and when prompted to install on which disk press CTRL+ALT+F2 to go into the terminal without installing
plug in the scanner usb
make sure target is connected to ethernet
Run: lsblk -f

If the SCANNER USB is mounted at /mnt/scanner, run:

sudo /mnt/scanner/waycube-scanner/run-scan.sh

Wait for: Hardware scan completed and submitted successfully.
Safely remove the SCANNER USB: sync

then: sudo umount /mnt/scanner

shut down live enviorment: sudo poweroff


YOU NEED THE 2 USBS PLUGGED IN target device

(the red SanDisk and the black Verbatim usb sticks)

PS: the usbs maybe have a different mount on a different device but most of the time its mounted at /mnt/scanner
if not then to do it manually: 

sudo mkdir -p /mnt/scanner

sudo mount /dev/sdb1 /mnt/scanner
Always start the launcher using:

sudo /mnt/scanner/waycube-scanner/run-scan.sh
