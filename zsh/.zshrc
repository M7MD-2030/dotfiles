# =====================================================================
# ZSH CONFIGURATION — Debian 13 / labwc / Kitty / Oh My Zsh / Powerlevel10k
# =====================================================================

# --- Powerlevel10k instant prompt (must stay near the top) ---
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# --- Oh My Zsh ---
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git sudo colored-man-pages zsh-autosuggestions zsh-syntax-highlighting)
[[ -f "$ZSH/oh-my-zsh.sh" ]] && source "$ZSH/oh-my-zsh.sh"
[[ -f "$HOME/.p10k.zsh" ]] && source "$HOME/.p10k.zsh"

# --- Environment ---
export LANG="en_US.UTF-8"
export EDITOR="nano"
export VISUAL="nano"
export PAGER="less"

# --- KVM lab paths ---
export ISO="/var/lib/libvirt/VMs/ISOs"
export DISK="/var/lib/libvirt/VMs/Storage"
export EVID="/var/lib/libvirt/VMs/Evidence"
export VIRTIO="$ISO/virtio-win.iso"

# --- PATH ---
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.npm-global/bin:$PATH"
export PATH="$HOME/.deno/bin:$PATH"
export GOPATH="$HOME/.go"
export PATH="$PATH:/usr/local/go/bin:$GOPATH/bin"
export PATH="/usr/games:$PATH"

# --- History ---
export HISTFILE="$HOME/.zsh_history"
export HISTSIZE=50000
export SAVEHIST=50000
setopt EXTENDED_HISTORY INC_APPEND_HISTORY SHARE_HISTORY
setopt HIST_IGNORE_DUPS HIST_IGNORE_ALL_DUPS HIST_SAVE_NO_DUPS
setopt HIST_IGNORE_SPACE HIST_EXPIRE_DUPS_FIRST HIST_VERIFY

# --- Zsh behavior ---
setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS EXTENDED_GLOB NO_CASE_GLOB INTERACTIVE_COMMENTS

# --- Aliases ---
alias ls='ls --color=auto'
alias ll='ls -lh --color=auto'
alias la='ls -lah --color=auto'
alias lt='ls -lahR --color=auto'
alias grep='grep --color=auto'
alias diff='diff --color=auto'
alias ip='ip -color=auto'

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias -- -='cd -'

alias gs='git status'
alias ga='git add'
alias gc='git commit -m'
alias gp='git push'
alias gl='git log --oneline --graph --decorate --all'
alias gd='git diff'
alias gco='git checkout'
alias gb='git branch'

alias c='clear'
alias h='history'
alias reload='source "$HOME/.zshrc"'
alias path='printf "%s\n" "$PATH" | tr ":" "\n"'
alias please='sudo'
alias ports='sudo ss -tulpn'
alias copy='wl-copy'
alias vm='virt-manager & disown'

# --- Package manager aliases (auto-detects distro) ---
if command -v apt >/dev/null 2>&1; then
    alias update='sudo apt update && sudo apt full-upgrade -y'
    alias install='sudo apt install'
    alias search='apt search'
elif command -v dnf >/dev/null 2>&1; then
    alias update='sudo dnf upgrade --refresh'
    alias install='sudo dnf install'
    alias search='dnf search'
elif command -v pacman >/dev/null 2>&1; then
    alias update='sudo pacman -Syu'
    alias install='sudo pacman -S'
    alias search='pacman -Ss'
fi

# --- Functions ---
mkcd() {
    [[ -z "$1" ]] && { echo "Usage: mkcd <directory>"; return 1; }
    mkdir -p -- "$1" && cd -- "$1"
}

bak() {
    [[ -z "$1" ]] && { echo "Usage: bak <file>"; return 1; }
    cp -- "$1" "$1.bak.$(date +%Y%m%d_%H%M%S)"
}

hgrep() {
    [[ -z "$1" ]] && { echo "Usage: hgrep <pattern>"; return 1; }
    history | grep --color=auto -- "$1"
}

psgrep() {
    [[ -z "$1" ]] && { echo "Usage: psgrep <pattern>"; return 1; }
    ps aux | grep -v grep | grep --color=auto -- "$1"
}

mpv() {
    command mpv "$@" > /dev/null 2>&1 &
    disown
}

# --- aria2 downloader ---
dl() {
    if ! command -v aria2c >/dev/null 2>&1; then
        echo "aria2c not found. Install it with: sudo apt install aria2"
        return 1
    fi
    [[ -z "$1" ]] && { echo "Usage: dl <url-or-magnet-link> [output-directory]"; return 1; }

    local url="$1"
    local dest_dir="${2:-$HOME/Downloads}"
    mkdir -p -- "$dest_dir"

    aria2c \
        --dir="$dest_dir" \
        --max-connection-per-server=16 \
        --split=16 \
        --min-split-size=1M \
        --max-concurrent-downloads=5 \
        --continue=true \
        --auto-file-renaming=false \
        --allow-overwrite=false \
        --file-allocation=falloc \
        --disk-cache=64M \
        --retry-wait=3 \
        --max-tries=0 \
        --summary-interval=1 \
        --console-log-level=warn \
        --download-result=full \
        "$url"

    local exit_code=$?
    if (( exit_code == 0 )); then
        echo "Download complete -> $dest_dir"
    else
        echo "Download failed or incomplete (code $exit_code)."
    fi
    return $exit_code
}

# --- YouTube downloader ---
ytdl() {
    if ! command -v yt-dlp >/dev/null 2>&1; then
        echo "yt-dlp not found. Install it first."
        return 1
    fi
    [[ -z "$1" ]] && { echo "Usage: ytdl <video-or-playlist-url>"; return 1; }
    local url="$1"
    local base_dir="$HOME/Youtube"
    mkdir -p -- "$base_dir"
    
    yt-dlp \
        --output "$base_dir/%(title)s.%(ext)s" \
        --format "bestvideo*[height<=1080]+bestaudio/best[height<=1080]" \
        --merge-output-format mp4 \
        --concurrent-fragments 4 \
        --downloader aria2c \
        --downloader-args "aria2c:-x16 -s16 -k1M" \
        --embed-chapters \
        --no-mtime \
        --force-overwrites \
        "$url"
    return $?
}
# --- fzf ---
[[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]] && source /usr/share/doc/fzf/examples/key-bindings.zsh
[[ -f /usr/share/doc/fzf/examples/completion.zsh ]] && source /usr/share/doc/fzf/examples/completion.zsh

# --- Deno ---
[[ -f "$HOME/.deno/env" ]] && source "$HOME/.deno/env"
. "/home/m7md/.deno/env"
export PATH="$HOME/.deno/bin:$PATH"
export LIBVIRT_DEFAULT_URI="qemu:///system"
alias ssh="kitty +kitten ssh"
export ANDROID_HOME=$HOME/.android-sdk/Sdk
export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools"
alias reboot="sudo /usr/sbin/reboot"
export LIBVIRT_DEFAULT_URI=qemu:///system
# reset a lab target from its golden base:  labreset win10-victim
labreset() {
  local vm="${1:?usage: labreset <vm-name>}"
  local base="$DISK/$vm-base.qcow2"
  [ -f "$base" ] || { echo "no base: $base"; return 1; }
  sudo chown "$USER":libvirt-qemu "$base" 2>/dev/null
  sudo chmod 0444 "$base" 2>/dev/null
  virsh destroy "$vm" 2>/dev/null
  rm -f "$DISK/$vm.qcow2"
  qemu-img create -f qcow2 -F qcow2 -b "$base" "$DISK/$vm.qcow2" >/dev/null || return 1
  virsh start "$vm"
}
