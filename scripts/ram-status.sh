#!/bin/bash
free -h --si | awk '/Mem:/ {print "  RAM " $3 "/" $2 "  |"}'
