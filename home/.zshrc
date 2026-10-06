# =====================================================================
#  ~/.zshrc — Arch Linux / Wayfire / Kitty / Powerlevel10k (no oh-my-zsh)
# =====================================================================


# ---------------------------------------------------------------------
# 1. Powerlevel10k instant prompt — must stay at the very top
# ---------------------------------------------------------------------
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi


# ---------------------------------------------------------------------
# 2. Environment
# ---------------------------------------------------------------------
export LANG="en_US.UTF-8"
export EDITOR="nano"
export VISUAL="nano"
export PAGER="less"

# colored man pages
export MANPAGER="less -R --use-color -Dd+r -Du+b"
export MANROFFOPT="-P -c"

# PATH
export PATH="$HOME/.local/bin:$HOME/.local/share/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# KVM lab
export LIBVIRT_DEFAULT_URI="qemu:///system"
export ISO="/var/lib/libvirt/VMs/ISOs"
export DISK="/var/lib/libvirt/VMs/Storage"
export EVID="/var/lib/libvirt/VMs/Evidence"
export VIRTIO="$ISO/virtio-win.iso"


# ---------------------------------------------------------------------
# 3. History
# ---------------------------------------------------------------------
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt EXTENDED_HISTORY SHARE_HISTORY
setopt HIST_IGNORE_DUPS HIST_IGNORE_ALL_DUPS HIST_SAVE_NO_DUPS
setopt HIST_IGNORE_SPACE HIST_EXPIRE_DUPS_FIRST HIST_VERIFY


# ---------------------------------------------------------------------
# 4. Shell options
# ---------------------------------------------------------------------
setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS
setopt EXTENDED_GLOB NO_CASE_GLOB
setopt INTERACTIVE_COMMENTS


# ---------------------------------------------------------------------
# 5. Completion
# ---------------------------------------------------------------------
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'


# ---------------------------------------------------------------------
# 6. Keybindings & line-editor widgets
# ---------------------------------------------------------------------
bindkey -e

# Up/Down: search history by what you've typed
bindkey '^[[A' history-beginning-search-backward
bindkey '^[OA' history-beginning-search-backward
bindkey '^[[B' history-beginning-search-forward
bindkey '^[OB' history-beginning-search-forward

# Home / End / Delete / Ctrl+Arrows
bindkey '^[[H'    beginning-of-line
bindkey '^[[F'    end-of-line
bindkey '^[[3~'   delete-char
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word

# auto-escape pasted URLs
autoload -Uz bracketed-paste-magic url-quote-magic
zle -N bracketed-paste bracketed-paste-magic
zle -N self-insert url-quote-magic

# Esc Esc: add/remove sudo on the current line
sudo-command-line() {
  [[ -z $BUFFER ]] && zle up-history
  if [[ $BUFFER == sudo\ * ]]; then BUFFER="${BUFFER#sudo }"; else BUFFER="sudo $BUFFER"; fi
  zle end-of-line
}
zle -N sudo-command-line
bindkey '\e\e' sudo-command-line


# ---------------------------------------------------------------------
# 7. Aliases
# ---------------------------------------------------------------------
# listing & color
alias ls='ls --color=auto'
alias ll='ls -lh --color=auto'
alias la='ls -lah --color=auto'
alias lt='ls -lahR --color=auto'
alias grep='grep --color=auto'
alias diff='diff --color=auto'
alias ip='ip -color=auto'

# navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias -- -='cd -'

# git
alias gs='git status'
alias ga='git add'
alias gc='git commit -m'
alias gp='git push'
alias gl='git log --oneline --graph --decorate --all'
alias gd='git diff'
alias gco='git checkout'
alias gb='git branch'

# shell & system
alias c='clear'
alias h='history'
alias reload='source "$HOME/.zshrc"'
alias path='printf "%s\n" "$PATH" | tr ":" "\n"'
alias please='sudo'
alias ports='sudo ss -tulpn'
alias copy='wl-copy'
# apps
alias zed='zeditor'
alias ssh='kitten ssh'
alias vm='virt-manager & disown'

# package manager (auto-detects distro)
if command -v pacman >/dev/null 2>&1; then
  alias update='sudo pacman -Syu'
  alias install='sudo pacman -S'
  alias search='pacman -Ss'
elif command -v apt >/dev/null 2>&1; then
  alias update='sudo apt update && sudo apt full-upgrade -y'
  alias install='sudo apt install'
  alias search='apt search'
elif command -v dnf >/dev/null 2>&1; then
  alias update='sudo dnf upgrade --refresh'
  alias install='sudo dnf install'
  alias search='dnf search'
fi


# ---------------------------------------------------------------------
# 8. Functions — general
# ---------------------------------------------------------------------
# make a directory and cd into it
mkcd() {
  [[ -z "$1" ]] && { echo "Usage: mkcd <directory>"; return 1; }
  mkdir -p -- "$1" && cd -- "$1"
}

# timestamped backup of a file
bak() {
  [[ -z "$1" ]] && { echo "Usage: bak <file>"; return 1; }
  cp -- "$1" "$1.bak.$(date +%Y%m%d_%H%M%S)"
}

# search shell history
hgrep() {
  [[ -z "$1" ]] && { echo "Usage: hgrep <pattern>"; return 1; }
  history | grep --color=auto -- "$1"
}

# search running processes
psgrep() {
  [[ -z "$1" ]] && { echo "Usage: psgrep <pattern>"; return 1; }
  ps aux | grep -v grep | grep --color=auto -- "$1"
}

# launch GUI apps detached from the terminal
unalias firefox mpv zathura imv open 2>/dev/null
function firefox { command firefox "$@" >/dev/null 2>&1 & disown; }
function mpv     { command mpv "$@"     >/dev/null 2>&1 & disown; }
function zathura { command zathura "$@" >/dev/null 2>&1 & disown; }
function imv     { command imv "$@"     >/dev/null 2>&1 & disown; }

# open files with their default app, detached from the terminal:  open file1 [file2 ...]
open() {
  [[ -z "$1" ]] && { echo "Usage: open <file> [file ...]"; return 1; }
  local f
  for f in "$@"; do
    setsid -f xdg-open "$f" >/dev/null 2>&1
  done
}


# ---------------------------------------------------------------------
# 9. Functions — downloads
# ---------------------------------------------------------------------
# fast download (http/ftp/torrent/magnet):  dl <url> [dir]
dl() {
  command -v aria2c >/dev/null 2>&1 || { echo "aria2c not found: sudo pacman -S aria2"; return 1; }
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

# libreoffice 
libreoffice() { SAL_USE_VCLPLUGIN=gtk3 command libreoffice "$@" >/dev/null 2>&1 & disown; }

# number + move already-downloaded playlist videos into their folder:  ytnum <playlist-url>
ytnum() {
  [[ "$1" != *list=* ]] && { echo "Usage: ytnum <playlist-url>"; return 1; }
  local out="$HOME/Youtube" name dir idx id f n=0

  name=$(yt-dlp --flat-playlist --cookies-from-browser firefox -I 1 \
         -o '%(playlist_title)s' --print filename "$1" 2>/dev/null)
  [[ -z "$name" ]] && { echo "Couldn't read playlist (YouTube blocked or still flagged?)"; return 1; }
  dir="$out/$name"
  mkdir -p -- "$dir"

  yt-dlp --flat-playlist --cookies-from-browser firefox \
         --print '%(playlist_index)s %(id)s' "$1" 2>/dev/null |
  while read -r idx id; do
    for f in "$out"/*"[$id]".*(N); do
      mv -n -- "$f" "$dir/$(printf '%03d' "$idx") - ${f:t}" && ((n++))
    done
  done

  echo "Numbered and moved $n files -> $dir"
}


# ---------------------------------------------------------------------
# 10. Functions — KVM lab
# ---------------------------------------------------------------------
# reset a lab target from its golden base:  labreset win10-victim
labreset() {
  local vm="${1:?usage: labreset <vm-name>}"
  local base="$DISK/$vm-base.qcow2"
  [[ -f "$base" ]] || { echo "no base: $base"; return 1; }
  sudo chown "$USER":libvirt-qemu "$base" 2>/dev/null
  sudo chmod 0444 "$base" 2>/dev/null
  virsh destroy "$vm" 2>/dev/null
  rm -f "$DISK/$vm.qcow2"
  qemu-img create -f qcow2 -F qcow2 -b "$base" "$DISK/$vm.qcow2" >/dev/null || return 1
  virsh start "$vm"
}


# ---------------------------------------------------------------------
# 10b. Python — uv + ruff + basedpyright (Rust-like workflow)
# ---------------------------------------------------------------------
export PIP_REQUIRE_VIRTUALENV=true        # pip refuses to touch system Python
export UV_PYTHON_PREFERENCE=only-managed  # uv uses its own Pythons, not pacman's

alias uvr='uv run'                        # like cargo run
alias uva='uv add'                        # like cargo add

# new project, like cargo new:  pynew <name>
pynew() {
  [[ -z "$1" ]] && { echo "Usage: pynew <project-name>"; return 1; }
  uv init --package --python 3.13 "$1" && cd -- "$1" || return 1
  uv add --dev ruff basedpyright pytest || return 1
  cat >> pyproject.toml <<'EOF'

[tool.ruff]
line-length = 100

[tool.ruff.lint]
select = ["E", "F", "W", "I", "B", "UP", "N", "SIM", "RUF", "PL", "ANN", "S", "PT"]
ignore = ["PLR2004"]  # allow plain numbers like ports

[tool.ruff.lint.per-file-ignores]
"tests/*" = ["S101", "ANN"]

[tool.basedpyright]
typeCheckingMode = "strict"
EOF
  mkdir -p tests
  printf 'def test_works() -> None:\n    assert 1 + 1 == 2\n' > tests/test_main.py
  git add -A >/dev/null 2>&1
  echo "✔ $1 ready  →  uvr $1   |   pycheck   |   zed ."
}

# format + lint + type-check + test, stops at first failure (like clippy + cargo test)
pycheck() {
  uv run ruff format && uv run ruff check --fix && uv run basedpyright && uv run pytest -q
}


# ---------------------------------------------------------------------
# 11. Tools, prompt & plugins — keep this section last
# ---------------------------------------------------------------------
# fzf: Ctrl+R history search, Ctrl+T file picker
source <(fzf --zsh)

# Powerlevel10k
source "$HOME/.local/share/powerlevel10k/powerlevel10k.zsh-theme"
[[ -f "$HOME/.p10k.zsh" ]] && source "$HOME/.p10k.zsh"

# plugins (syntax-highlighting must be the very last line)
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# tm [name] — attach to tmux session, create it if missing (default: main)
tm() { tmux new -A -s "${1:-main}"; }

wvreset() {
  sudo virsh destroy winvault-dev 2>/dev/null
  sudo rm -f $DISK/winvault-dev.qcow2
  sudo qemu-img create -q -f qcow2 -F qcow2 -b $DISK/winvault-dev-base.qcow2 $DISK/winvault-dev.qcow2
  echo "winvault-dev reset to clean base"
}

wvsave() {
  sudo virsh domstate winvault-dev | grep -q "shut off" || { echo "Shut the VM down first (Stop-Computer)"; return 1; }
  sudo chmod 644 $DISK/winvault-dev-base.qcow2 &&
  sudo qemu-img commit $DISK/winvault-dev.qcow2 &&
  sudo chmod 444 $DISK/winvault-dev-base.qcow2 &&
  wvreset && echo "Saved as the new clean base"
}

# YouTube video or playlist -> ~/Youtube:  ytdl <url>
# single videos: no sleeps (fast). playlists: own folder, numbered 001, 002, ... with sleeps to avoid rate limits
ytdl() {
  [[ -z "$1" ]] && { echo "Usage: ytdl <video-or-playlist-url>"; return 1; }
  local out="$HOME/Youtube"
  local tmpl='%(title)s [%(id)s].%(ext)s'
  local -a mode=(--no-playlist --no-download-archive)
  if [[ "$1" == *list=* ]]; then
    tmpl='%(playlist_title)s/%(playlist_index)03d - %(title)s [%(id)s].%(ext)s'
    mode=(--yes-playlist --download-archive "$out/.archive.txt" --sleep-requests 1 --sleep-interval 3 --max-sleep-interval 8)
  fi
  mkdir -p -- "$out"

  yt-dlp \
    "${mode[@]}" \
    --cookies-from-browser firefox \
    --extractor-args "youtube:player_client=default,mweb" \
    -f 'bv*[height<=1080]+ba/b[height<=1080]/b' \
    --merge-output-format mkv \
    --embed-chapters \
    -N 16 \
    --http-chunk-size 10M \
    --retries infinite --fragment-retries infinite \
    --socket-timeout 30 \
    --ignore-errors \
    --no-mtime \
    -P "$out" \
    -o "$tmpl" \
    "$@"
}
# big countdown with sound + notification when it ends:  td 25m [label]
td() {
  [[ -z $1 ]] && { echo "Usage: td <25m|1h30m|90s> [label]"; return 1; }
  local label=${2:-Timer}
  termdown -T "$label" "$1" || return      # Ctrl+C = no sound
  notify-send -u critical -a timer "$label" "Time's up"
  pw-play /usr/share/sounds/freedesktop/stereo/complete.oga 2>/dev/null &!
}
