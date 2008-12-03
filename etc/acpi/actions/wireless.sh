#!/bin/sh

. /usr/share/eeepc-acpi-scripts/functions.sh

detect_rfkill eeepc-wlan
wlan_control="$RFKILL"
[ -e $wlan_control ] || wlan_control=/sys/devices/platform/eeepc/wlan # pre-2.6.28
[ -e $wlan_control ] || wlan_control=/proc/acpi/asus/wlan # pre-2.6.26

case $1 in
    on|enable)
	if [ $(cat $wlan_control) = 0 ]; then
	    echo 1 > $wlan_control
            detect_wlan
	    if [ "$WLAN_MOD" = 'ath_pci' ]; then
		# madwifi needs some handholding
		modprobe $WLAN_MOD
		# adding a sleep here, due to some bug the driver loading is not atomic here
		# and could cause ifconfig to fail
		sleep 1
		if ! ifconfig $WLAN_IF up; then exec $0 off; fi
	    fi
	fi
	;;
    off|disable)
	if [ $(cat $wlan_control) = 1 ]; then
            detect_wlan
	    if [ "$WLAN_MOD" = 'ath_pci' ]; then
		ifdown --force $WLAN_IF
		modprobe -r $WLAN_MOD
	    fi
	    echo 0 > $wlan_control
	fi
	;;
    *)
	echo "Usage: $0 [on|off]"
	exit 1
	;;
esac
