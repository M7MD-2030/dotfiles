#!/bin/bash
stamp="$HOME/.cache/unplugged-at"
hide_time="$HOME/.cache/tt-hide-time"   # created/removed by `tt`
sound=/usr/share/sounds/freedesktop/stereo/dialog-warning.oga
mkdir -p "$HOME/.cache"
exec {sfd}<> <(:)

read -r _ u n s i w q sq st _ < /proc/stat
p_idle=$((i + w)); p_total=$((u + n + s + i + w + q + sq + st))
warned=100
dtick=0

on_ac() {
  for d in /sys/class/power_supply/*; do
    [[ $(<"$d/type") == Mains && $(<"$d/online") == 1 ]] && return 0
  done
  return 1
}

bt_status() {
  bt=""
  local line mac name pct
  line=$(timeout 2 bluetoothctl devices Connected 2>/dev/null </dev/null | head -n1)
  [[ -z $line ]] && return
  line=${line#Device }
  mac=${line%% *}
  name=${line#* }
  pct=$(timeout 2 bluetoothctl info "$mac" 2>/dev/null </dev/null \
        | sed -n 's/.*Battery Percentage:.*(\([0-9]\+\)).*/\1/p')
  [[ -n $pct ]] && bt="${name:0:14} ${pct}% | " || bt="${name:0:14} | "
}

slow() {
  # CPU
  read -r _ u n s i w q sq st _ < /proc/stat
  idle=$((i + w)); total=$((u + n + s + i + w + q + sq + st))
  dt=$((total - p_total)); di=$((idle - p_idle))
  (( dt > 0 )) && cpu=$(( 100 * (dt - di) / dt )) || cpu=0
  p_idle=$idle; p_total=$total

  # RAM
  while read -r k v _; do
    case $k in MemTotal:) t=$v ;; MemAvailable:) a=$v ;; esac
  done < /proc/meminfo
  used=$(( (t - a) * 10 / 1048576 )); tot=$(( t * 10 / 1048576 ))
  ram="RAM $((used / 10)).$((used % 10))/$((tot / 10)).$((tot % 10))G"

  # Disk: used/total of /, refreshed about once a minute
  if (( dtick <= 0 )); then
    read -r du ds < <(df -BG --output=used,size / | tail -n1)
    disk="DISK ${du%G}/${ds}"
    dtick=6
  fi
  ((dtick--))

  # Wi-Fi: SSID + signal %
  ssid=$(iw dev wlan0 link 2>/dev/null | awk -F': ' '/SSID/{print $2}')
  sig=0
  while read -r ifc _ lq _; do
    [[ $ifc == wlan0: ]] && sig=${lq%.}
  done < /proc/net/wireless
  if [[ -n $ssid ]]; then net="$ssid $(( sig * 100 / 70 ))%"; else net="NET offline"; fi

  # Keyboard language (written by kblang.py)
  f="${XDG_RUNTIME_DIR:-/tmp}/kb-lang"
  if [[ -r $f ]]; then lang=$(<"$f"); else lang=EN; fi

  # Battery + unplugged timer + low-battery alarm
  bat=$(</sys/class/power_supply/BAT0/capacity)
  if on_ac; then
    rm -f "$stamp"; warned=100
    batt="CHR ${bat}%"
  else
    printf -v now '%(%s)T' -1
    [[ -f $stamp ]] || echo "$now" > "$stamp"
    el=$(( now - $(<"$stamp") ))
    printf -v timer '%d:%02d' $((el / 3600)) $(((el % 3600) / 60))
    batt="BAT ${bat}% ${timer}"
    if (( bat <= 30 && bat < warned )); then
      warned=$bat
      notify-send -u critical -a battery "Battery low: ${bat}%" "Plug in the charger"
      pw-play "$sound" &
    fi
  fi

  # Volume + mic
  m=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null)
  [[ $m == *MUTED* ]] && mic="MIC OFF | " || mic=""

  # Bluetooth: connected device + battery
  bt_status

  info="$bt$mic$lang | $net | CPU ${cpu}% | $ram | $disk | $batt"
}

refresh=1
tick=0
trap 'refresh=1' USR1

while :; do
  if (( refresh || tick >= 10 )); then slow; refresh=0; tick=0; fi
  if [[ -f $hide_time ]]; then
    printf '%s \n' "$info"                                        # time hidden by `tt`
  else
    printf '%s | %(%y/%m/%d  %I:%M:%S %p)T \n' "$info" -1
  fi
  read -rt 1 -u "$sfd"
  ((tick++))
done
