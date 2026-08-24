#!/bin/bash
USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}')
printf "  CPU %.0f%%  |\n" "$USAGE"
