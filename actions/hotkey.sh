#!/bin/sh

# do nothing if package is removed
[ -d /usr/share/doc/eeepc-acpi-scripts ] || exit 0

. /etc/default/eeepc-acpi-scripts
. /usr/share/eeepc-acpi-scripts/functions.sh
code=$3

notify() {
    echo "$@"  # for /var/log/acpid
    if [ -S /tmp/.X11-unix/X0 ]; then
        detect_x_display

    if [ "x$ENABLE_OSD" = "xno" ]; then
        return
    fi

    OSD_SHOWN=

    # try to show a nice OSD notification via GNOME OSD service
    GOSDC=/usr/bin/gnome-osd-client
    if [ -x $GOSDC ]; then
	if ps -u $user -o cmd= | grep -q '^/usr/bin/python /usr/bin/gnome-osd-event-bridge'; then
	    if echo "$2" | grep -q '[0-9]'; then
		animations='off'
	    else
		animations='on'
	    fi
	    echo "<message id='eee-$1' osd_fake_translucent_bg='off' osd_vposition='bottom' animations='$animations' hide_timeout='1200' osd_halignment='center'>$@</message>" \
		| sudo -u $user $GOSDC -s --dbus
	    OSD_SHOWN=1
	fi
    fi

    if [ -z "$OSD_SHOWN" ]; then
	killall -q aosd_cat
	if [ -n "$2" -a -z "$(echo $2 | sed 's/[0-9]//g')" ]; then
		echo "$@%" | aosd_cat -f 0 -u 100 -o 0 -n "$OSD_FONT" &
	else
		echo "$@" | aosd_cat -n "$OSD_FONT" -f 100 -u 1000 -o 100 &
	fi
    fi
    else
	echo "$@" > /dev/console
    fi
}

show_wireless() {
    detect_wlan
    if grep -q $WLAN_IF /proc/net/wireless; then
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

handle_blank_screen() {
    if [ -S /tmp/.X11-unix/X0 ]; then
	detect_x_display

	if [ -n "$XAUTHORITY" ]; then
	    xset dpms force off
	fi
    fi
}

show_bluetooth() {
    if bluetooth_is_on; then
	notify Bluetooth On
    else
	notify Bluetooth Off
    fi
}

handle_bluetooth_toggle() {
    . /etc/acpi/lib/bluetooth.sh
    if [ -e $BT_CTL ] || [ "$BLUETOOTH_FALLBACK_TO_HCITOOL" = "yes" ]; then
	toggle_bluetooth
	show_bluetooth
    else
	notify Bluetooth unavailable
    fi
}

show_camera() {
    if camera_is_on; then
	notify Camera Enabled
    else
	notify Camera Disabled
    fi
}

handle_camera_toggle() {
    . /etc/acpi/lib/camera.sh
    if [ -e $CAM_CTL ]; then
	toggle_camera
	show_camera
    else
	notify Camera unavailable
    fi
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
    0000001a)
	# soft-buton 1
	if [ "${SOFTBTN1_ACTION:-handle_blank_screen}" != 'NONE' ]; then
	    ${SOFTBTN1_ACTION:-handle_blank_screen}
	fi
	;;
    0000001b)
	# soft-buton 2
	if [ "${SOFTBTN2_ACTION}" != 'NONE' ]; then
	    ${SOFTBTN2_ACTION}
	fi
	;;
    0000001c)
	# soft-buton 3
	if [ "${SOFTBTN3_ACTION:-handle_camera_toggle}" != 'NONE' ]; then
	    ${SOFTBTN3_ACTION:-handle_camera_toggle}
	fi
	;;
    0000001d)
	# soft-buton 4
	if [ "${SOFTBTN4_ACTION:-handle_bluetooth_toggle}" != 'NONE' ]; then
	    ${SOFTBTN4_ACTION:-handle_bluetooth_toggle}
	fi
	;;
esac
