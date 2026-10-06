#!/bin/bash
# usage: osd.sh vol-up|vol-down|vol-mute|mic-mute|br-up|br-down

SINK="@DEFAULT_AUDIO_SINK@"
SOURCE="@DEFAULT_AUDIO_SOURCE@"
STEP=5

# 150% on the laptop speakers, 100% on bluetooth / usb
max_vol() {
  if wpctl inspect "$SINK" 2>/dev/null | grep -q 'node.name = "bluez'; then
    echo 100
  else
    echo 150
  fi
}

notify() {  # notify <id> <title> <percent>
  notify-send -a osd -h string:x-canonical-private-synchronous:"$1" \
              -h int:value:"$3" "$2"
}

vol_now() {
  local v
  v=$(wpctl get-volume "$SINK" 2>/dev/null) || { echo 0; return; }
  v=${v#Volume: }
  v=${v%% *}
  printf '%d' "$(( 10#${v/./} ))" 2>/dev/null || echo 0
}

is_muted() { [[ $(wpctl get-volume "$SINK" 2>/dev/null) == *MUTED* ]]; }

set_vol() {
  local p=$1 max
  max=$(max_vol)
  (( p < 0 ))     && p=0
  (( p > max ))   && p=$max
  wpctl set-volume -l 1.5 "$SINK" "${p}%"
  wpctl set-mute "$SINK" 0
  if (( p > 100 )); then
    notify vol "Volume ${p}%  (boosted)" "$p"
  else
    notify vol "Volume ${p}%" "$p"
  fi
}

case $1 in
  vol-up)   set_vol $(( $(vol_now) + STEP )) ;;
  vol-down) set_vol $(( $(vol_now) - STEP )) ;;

  vol-mute)
    wpctl set-mute "$SINK" toggle
    if is_muted; then
      notify vol "Volume muted" 0
    else
      notify vol "Volume $(vol_now)%" "$(vol_now)"
    fi
    ;;

  mic-mute)
    wpctl set-mute "$SOURCE" toggle
    if [[ $(wpctl get-volume "$SOURCE") == *MUTED* ]]; then
      notify mic "Microphone muted" 0
    else
      notify mic "Microphone on" 100
    fi
    pkill -USR1 -f status.sh
    ;;

  br-up)
    brightnessctl -q set "${STEP}%+"
    notify br "Brightness $(brightnessctl -m | cut -d, -f4)" \
              "$(brightnessctl -m | cut -d, -f4 | tr -d '%')"
    ;;
  br-down)
    brightnessctl -q set "${STEP}%-"
    notify br "Brightness $(brightnessctl -m | cut -d, -f4)" \
              "$(brightnessctl -m | cut -d, -f4 | tr -d '%')"
    ;;
esac
