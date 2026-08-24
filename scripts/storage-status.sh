#!/bin/bash
df -h / | awk 'NR==2 {print "  DISK " $3 "/" $2 "  |"}'
