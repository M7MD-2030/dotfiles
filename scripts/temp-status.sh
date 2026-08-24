#!/bin/bash
MAX=0
for ZONE in /sys/class/thermal/thermal_zone*/temp; do
  T=$(cat "$ZONE" 2>/dev/null)
  [ -z "$T" ] && continue
  T=$(( T / 1000 ))
  [ "$T" -gt "$MAX" ] && MAX=$T
done
echo "  TEMP ${MAX}°C  |"
