# USB Hardware Scanner Troubleshooting

This guide covers common problems when using the Waycube USB hardware scanner.

## Quick checklist

Before troubleshooting, confirm the following:

- The HP/InvenTree server is powered on.
- The receiver is running and reachable at `http://192.168.100.231:8000`.
- The target computer is connected to the same local network.
- The Ubuntu boot USB and SCANNER USB are connected.
- You are running Ubuntu in Live mode, not installing Ubuntu on the target computer.

## Scanner launcher cannot be found

### Symptom

You see an error similar to:

```text
No such file or directory
```

### Cause

The SCANNER USB is not mounted at the path used in the command, or the path contains a typo.

### Fix

Find connected disks and mount points:

```bash
lsblk -f
```

Look for the USB labelled `SCANNER` or for the device containing the `waycube-scanner` folder.

If the scanner is mounted at `/mnt/scanner`, run:

```bash
sudo /mnt/scanner/waycube-scanner/run-scan.sh
```

If it is mounted at `/media/ubuntu/SCANNER`, run:

```bash
sudo /media/ubuntu/SCANNER/waycube-scanner/run-scan.sh
```

Do not put a space inside a path. This is incorrect:

```bash
/mnt/scanner/ waycube-scanner/run-scan.sh
```

This is correct:

```bash
/mnt/scanner/waycube-scanner/run-scan.sh
```

## SCANNER USB is not mounted

### Symptom

The SCANNER USB does not appear in `/mnt/scanner` or `/media/ubuntu/SCANNER`.

### Fix

List available disks:

```bash
lsblk -f
```

Find the SCANNER USB partition, such as `/dev/sdb1`. Then mount it manually:

```bash
sudo mkdir -p /mnt/scanner
sudo mount /dev/sdb1 /mnt/scanner
```

Only use `/dev/sdb1` if `lsblk -f` shows that it is the SCANNER USB. The device name may be different.

Confirm the scanner files exist:

```bash
ls -l /mnt/scanner/waycube-scanner/
```

Expected files include:

```text
hardware-scan.py
run-scan.sh
requirements.txt
```

## Permission denied

### Symptom

You see:

```text
Permission denied
```

### Fix

Run the launcher with `sudo`:

```bash
sudo /mnt/scanner/waycube-scanner/run-scan.sh
```

If the launcher is not executable, restore its permission:

```bash
sudo chmod 700 /mnt/scanner/waycube-scanner/run-scan.sh
```

## Scanner token or authorization error

### Symptoms

You may see an error about a missing, invalid, unauthorized, or unconfigured scanner token.

### Fix

The token saved in `run-scan.sh` must match the token configured on the HP server as `WAYCUBE_SCANNER_TOKEN`.

On the HP server, confirm the expected environment-variable name in the application code:

```bash
grep -n -C 3 'TOKEN' ~/waycube-hardware/server/app.py
```

Do not share the token in screenshots, messages, or GitHub.

If the token is changed on the HP server, update the token inside the SCANNER USB launcher and keep the launcher permission restricted:

```bash
sudo chmod 700 /mnt/scanner/waycube-scanner/run-scan.sh
```

## Server error: scanner token not configured

### Symptom

You see:

```text
SERVER ERROR (500): Scanner token is not configured on the server.
```

### Cause

The HP server application was started without its required scanner-token environment variable.

### Fix

On the HP server, ensure the server environment contains the configured scanner token and restart the receiver. For example, from the Waycube project directory:

```bash
cd ~/waycube-hardware
set -a
source .env
set +a
source .venv/bin/activate
cd server
python -m uvicorn app:app --host 0.0.0.0 --port 8000
```

Use the actual variable name required by `app.py`, commonly `WAYCUBE_SCANNER_TOKEN`.

## Cannot reach the HP server

### Symptoms

The scan may report a connection error, timeout, refused connection, or an unreachable server.

### Fix

1. Confirm the target machine is connected to the local network.
2. Confirm the HP server is powered on.
3. On the HP server, confirm the receiver is running on port 8000.
4. From the Ubuntu Live environment, test reachability:

```bash
ping -c 4 192.168.100.231
```

5. Test the server HTTP endpoint:

```bash
curl -I http://192.168.100.231:8000
```

If the HP server's IP address has changed, update `run-scan.sh` on the SCANNER USB with the new address.

## Computer is already registered

### Symptom

You see:

```text
SERVER STATUS: already_registered
SERVER MESSAGE: This computer is already registered. Matched by serial_number.
Hardware scan completed and submitted successfully.
```

### Meaning

This is successful. The server found a computer with the same serial number and avoided creating a duplicate record.

No repair is needed.

## Hardware data was saved locally

### Symptom

You see a message similar to:

```text
The scan was saved locally at /tmp/waycube-hardware-scan.json.
```

### Meaning

The scan was collected, but could not be sent to the server.

### Fix

Fix the network or server issue, then rerun the scanner while the target computer is still in the Ubuntu Live session. The launcher will create a new scan and attempt submission again.

If needed, inspect the saved file:

```bash
cat /tmp/waycube-hardware-scan.json
```

Do not share the file publicly if it contains device serial numbers or other inventory data.

## Python command or launcher syntax errors

### Symptoms

You may see messages such as:

```text
hardware-scan.py: command not found
--token: command not found
can't find '__main__' module
```

### Cause

The command inside `run-scan.sh` was split onto multiple physical lines without valid line-continuation characters.

### Fix

Open the launcher:

```bash
sudo nano /mnt/scanner/waycube-scanner/run-scan.sh
```

The launch command must be one physical line. It should follow this pattern:

```bash
sudo python3 /mnt/scanner/waycube-scanner/hardware-scan.py --server-url http://192.168.100.231:8000 --token "$T"
```

Do not press Enter in the middle of that command. The editor may wrap the line visually; that is fine as long as it remains one physical line.

Save Nano with:

```text
Ctrl+O, Enter, Ctrl+X
```

Then test the launcher:

```bash
sudo /mnt/scanner/waycube-scanner/run-scan.sh
```

## Boot loop after scanning

### Symptom

The target computer repeatedly restarts or returns to a boot screen after using the USB drives.

### Fix

1. Hold the power button for about 10–15 seconds until the computer is fully off.
2. Remove both USB drives.
3. Disconnect any other unnecessary USB devices.
4. Wait about 10 seconds.
5. Turn the computer on normally.

If it still does not start normally, enter BIOS/UEFI during startup and make sure the internal SSD or normal operating system is first in the boot order.

## Safe USB removal

### Symptoms

You are unsure how to remove the SCANNER USB safely, or the `unmount` command is not found.

### Fix

The command is spelled `umount`, without `n`.

Run these as two separate commands:

```bash
sync
```

Then:

```bash
sudo umount /mnt/scanner
```

If the SCANNER USB is mounted elsewhere, substitute its actual mount path.

No output usually means the command succeeded. Remove only the SCANNER USB after it has been unmounted.

Do not remove the Ubuntu boot USB while Ubuntu is still running from it. First shut the computer down:

```bash
sudo poweroff
```

Remove the Ubuntu boot USB only after the computer has powered off.

## Security notes

- The SCANNER USB launcher contains a token that authorizes hardware-scan submissions.
- Use the scanner only on the trusted local network.
- Keep the SCANNER USB physically secure.
- Never commit the real token, `run-scan.sh`, or a `.env` file containing secrets to a public GitHub repository.
- If the USB is lost or the token is exposed, replace the scanner token on the HP server and update the SCANNER USB launcher.
