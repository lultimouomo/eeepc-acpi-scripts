#!/bin/sh

. /usr/share/eeepc-acpi-scripts/functions.sh

detect_rfkill eeepc-wlan wifi
wlan_control="$RFKILL"

if ! have_dev_rfkill; then
  [ -n "$wlan_control" -a -e $wlan_control ] \
    || wlan_control=/sys/devices/platform/eeepc/wlan # pre-2.6.28
  [ -e "$wlan_control" ] || wlan_control=/proc/acpi/asus/wlan # pre-2.6.26
fi

STATE="$(get_rfkill "$wlan_control")"

cmd="$1"
if [ "$cmd" = toggle ]; then
    cmd=$((1-STATE))
fi

case "$cmd" in
    detect)
	exit "$STATE"
	;;
    on|enable|1)
	if [ "$STATE" = 0 ]; then
	    set_rfkill "$wlan_control" 1
            wakeup_wicd
	fi
	;;
    off|disable|0)
	if [ "$STATE" = 1 ]; then
            # rt2860 needs to be idle when shut down
            if lsmod | grep -q rt2860sta; then
                ifconfig wlan0 down || ifconfig ra0 down
                modprobe -r rt2860sta
            fi
	    set_rfkill "$wlan_control" 0
	fi
	;;
    *)
	echo "Usage: $0 [on|off|detect]"
	exit 1
	;;
esac
