#!/bin/sh

# do nothing if package is removed
[ -d /usr/share/doc/eeepc-acpi-scripts ] || exit 0

. /etc/default/eeepc-acpi-scripts
code=$3

notify() {
    echo "$@"  # for /var/log/acpid
    if [ -S /tmp/.X11-unix/X0 ]; then
	export DISPLAY=:0
	user=$(who | sed -n '/ (:0[\.0]*)$\| :0 /{s/ .*//p;q}')
        home=$(getent passwd $user | cut -d: -f6)
	XAUTHORITY=$home/.Xauthority
	[ -f $XAUTHORITY ] && export XAUTHORITY

    if [ "x$ENABLE_OSD" = "xno" ]; then
        return
    fi

	killall -q aosd_cat
	if [ -n "$2" -a -z "$(echo $2 | sed 's/[0-9]//g')" ]; then
		echo "$@%" | aosd_cat -f 0 -u 100 -o 0 -n "$OSD_FONT" &
	else
		echo "$@" | aosd_cat -n "$OSD_FONT" -f 100 -u 1000 -o 100 &
	fi
    else
	echo "$@" > /dev/console
    fi
}

show_wireless() {
    if grep -q ath0 /proc/net/wireless; then
	status=On
    else
	status=Off
    fi
    notify Wireless $status
}

show_muteness() {
    status=$(amixer get $VOLUME_LABEL | sed -n '/%/{s/.*\[\(on\|off\)\].*/\u\1/p;q}')
    notify Audio $status
}

show_volume() {
    percent=$(amixer get $VOLUME_LABEL | sed -n '/%/{s/.*\[\(.*\)%\].*/\1/p;q}')
    notify Volume $percent
}

#show_brightness() {
#    # final digit of ACPI code is brightness level in hex
#    level=0x${code:${#code}-1}
#    # convert hex digit to percent
#    percent=$(((100 * $level + 8) / 15))
#    notify Brightness $percent
#}

case $code in
    # Fn+F2 -- toggle wireless
    00000010)
	/etc/acpi/actions/wireless.sh on
	show_wireless
	;;
    00000011)
	/etc/acpi/actions/wireless.sh off
	show_wireless
	;;
    # Fn+F7 -- mute/unmute speakers
    00000013)
	# muting $VOLUME_LABEL affects the headphone jack but not the speakers
	amixer -q set $VOLUME_LABEL toggle
	# muting $HEADPHONE_LABEL affects the speakers but not the headphone jack
	amixer -q set $HEADPHONE_LABEL toggle
	show_muteness
	;;
    # Fn+F8 -- decrease volume
    00000014)
	amixer -q set $VOLUME_LABEL 2- unmute
	amixer -q set $HEADPHONE_LABEL on
	show_volume
	;;
	# F+F5 -- toggle vga
	0000003[012])
	notify
	/etc/acpi/actions/vga-toggle.sh
	;;
    # Fn+F9 -- increase volume
    00000015)
	amixer -q set $VOLUME_LABEL 2+ unmute
	amixer -q set $HEADPHONE_LABEL on
	show_volume
	;;
    # Fn+F3 -- decrease brightness
    # Fn+F4 -- increase brightness
    0000002?)
	# actual brightness change is handled in hardware
	;;
esac
