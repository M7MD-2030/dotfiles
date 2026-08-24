#!/bin/bash
THRESHOLD=31

CAPACITY=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null)
STATUS=$(cat /sys/class/power_supply/BAT*/status 2>/dev/null)

if [ -z "$CAPACITY" ]; then
    exit 0
fi

# Only nag while discharging (skip if charging)
if [ "$STATUS" = "Discharging" ] && [ "$CAPACITY" -lt "$THRESHOLD" ]; then
    notify-send -u critical -i battery-low "Battery Low" "${CAPACITY}% remaining"
fi
