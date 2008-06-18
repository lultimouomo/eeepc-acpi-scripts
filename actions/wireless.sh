#!/bin/sh

wlan_control=/proc/acpi/asus/wlan

case $1 in
    on|enable)
	if [ $(cat $wlan_control) = 0 ]; then
	    modprobe -r pciehp
	    modprobe pciehp pciehp_force=1
	    echo 1 > $wlan_control
	    modprobe ath_pci
	    # adding a sleep here, due to some bug the driver loading is not atomic here
	    # and could cause ifconfig to fail
	    sleep 1
	    if ! ifconfig ath0 up; then exec $0 off; fi
	fi
	;;
    off|disable)
	if [ $(cat $wlan_control) = 1 ]; then
	    ifdown --force ath0
	    modprobe -r ath_pci
	    echo 0 > $wlan_control
	fi
	;;
    *)
	echo "Usage: $0 [on|off]"
	exit 1
	;;
esac
