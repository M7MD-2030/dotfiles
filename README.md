# dotfiles
Laptop setup (Arch + Wayfire). Paths mirror the system:
- `home/...`      → `~/...`
- `usr/local/bin` → `/usr/local/bin` (needs sudo)
- `etc/...`       → `/etc/...` (needs sudo — hosts blocklist, Firefox policies)

Restore:
```
cp -a home/. ~/
sudo cp -a usr/local/bin/. /usr/local/bin/
sudo cp -a etc/. /etc/
```
