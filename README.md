# dotfiles

Personal config backup — m7md@forge (Debian 13, GNOME → migrating to Openbox)

## Structure
- `zsh/`    → .zshrc, .zprofile, .p10k.zsh, .gitconfig
- `kitty/`  → kitty terminal config
- `zed/`    → Zed editor config
- `scripts/`→ custom .local/bin scripts (battery/cpu/ram/storage/temp status, cinit, cffi-gen-src)

## Setup on a fresh machine
```bash
cp zsh/.zshrc zsh/.zprofile zsh/.p10k.zsh zsh/.gitconfig ~/
cp -r kitty/* ~/.config/kitty/
cp -r zed/* ~/.config/zed/
cp scripts/* ~/.local/bin/
chmod +x ~/.local/bin/*.sh ~/.local/bin/cinit ~/.local/bin/cffi-gen-src
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

## Zsh plugins (clone separately, not in this repo)
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k
