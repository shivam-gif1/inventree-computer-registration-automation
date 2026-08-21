(MANUAL)
WHEN USING GENERATE HARDWARE REPORT.SH AFTER THAT USE CHECK-HARDWARE-REPORT.SH IMMEDIATLY
SO FIRST USE generate-hardware-report.sh AND THEN USE check-hardware-report.sh

# Ubuntu Server Live USB workflow

1. Boot the target computer from the Waycube Ubuntu Server Live USB.
2. Do not install Ubuntu.
3. Connect to a network.
4. Run:

```bash
sudo hardware-scan
```

5. Review the terminal summary.
6. The scanner submits the scan to the Waycube registration server.
7. Record the returned InvenTree result or error.
8. Power off and remove the USB.
