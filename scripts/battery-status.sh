#!/bin/bash
BAT=$(upower -e | grep -i BAT | head -n1)
STATE=$(upower -i "$BAT" | awk '/state/ {print $2}')
STATEFILE="$HOME/.cache/battery_last_transition"
LASTSTATE=""
[ -f "$STATEFILE" ] && LASTSTATE=$(cut -d'|' -f1 "$STATEFILE")
if [ "$STATE" != "$LASTSTATE" ]; then
    echo "$STATE|$(date +%s)" > "$STATEFILE"
fi
TRANSITION_TS=$(cut -d'|' -f2 "$STATEFILE")
NOW=$(date +%s)
ELAPSED_MIN=$(( (NOW - TRANSITION_TS) / 60 ))
HOURS=$(( ELAPSED_MIN / 60 ))
MINUTES=$(( ELAPSED_MIN % 60 ))
if [ "$STATE" = "charging" ]; then
    LABEL="CHR"
else
    LABEL="BAT"
fi
echo "  ${LABEL} (${HOURS}h ${MINUTES}m)  |"
