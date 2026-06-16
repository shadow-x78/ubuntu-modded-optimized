# Troubleshooting

## VNC Disconnects on Screen Lock

**Fix:** UMO runs `termux-wake-lock` automatically. If it still happens:
```bash
termux-wake-lock
~/umo-start.sh
```

## No Audio in Proot

**Fix:**
```bash
~/umo-start.sh        # Starts pulseaudio automatically
# Or manually:
pulseaudio --start
```

## systemctl Fails

**Fix:** UMO installs a shell-compatible `systemctl` emulator:
```bash
systemctl start ssh
systemctl stop ssh
systemctl status ssh
```

## Black Screen / VNC Not Connecting

**Fix:**
```bash
~/umo-stop.sh
~/umo-start.sh
```

## Low Storage During Install

**Fix:** Clear Termux cache:
```bash
pkg clean
rm -rf ~/.umo/cache
```

## Still Stuck?

Open an issue at: https://github.com/Shadow-x78/termux-ubuntu-umo/issues
