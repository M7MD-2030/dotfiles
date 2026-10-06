#!/bin/sh
dir="$HOME/Pictures/Screenshots"
mkdir -p "$dir"
f="$dir/$(date +%y-%m-%d_%H-%M-%S).png"

case "$1" in
  area) g=$(slurp) || exit 0; grim -g "$g" "$f" ;;
  full) grim "$f" ;;
  *) exit 1 ;;
esac

wl-copy --type image/png < "$f"
notify-send -a screenshot -i "$f" "Screenshot copied" "${f##*/}"
