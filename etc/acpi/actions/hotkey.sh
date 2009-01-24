#!/bin/sh

# do nothing if package is removed
PKG=eeepc-acpi-scripts
FUNC_LIB=/usr/share/$PKG/functions.sh
DEFAULT=/etc/default/$PKG
[ -e $FUNC_LIB ] || exit 0

case $(runlevel) in
    *0|*6)
	exit 0
	;;
esac

if [ -e "$DEFAULT" ]; then . "$DEFAULT"; fi
. $FUNC_LIB

. /etc/acpi/lib/notify.sh
code=$3

handle_mute_toggle() {
    /etc/acpi/actions/volume.sh toggle
}

handle_volume_up() {
    /etc/acpi/actions/volume.sh up
}

handle_volume_down() {
    /etc/acpi/actions/volume.sh down
}

show_wireless() {
    detect_wlan
    if grep -q $WLAN_IF /proc/net/wireless; then
	status=On
    else
	status=Off
    fi
    notify wireless "Wireless $status"
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
	notify bluetooth 'Bluetooth On'
    else
	notify bluetooth 'Bluetooth Off'
    fi
}

handle_bluetooth_toggle() {
    . /etc/acpi/lib/bluetooth.sh
    if [ -e $BT_CTL ] || [ "$BLUETOOTH_FALLBACK_TO_HCITOOL" = "yes" ]; then
	toggle_bluetooth
	show_bluetooth
    else
	notify error 'Bluetooth unavailable'
    fi
}

show_camera() {
    if camera_is_on; then
	notify camera 'Camera Enabled'
    else
	notify camera 'Camera Disabled'
    fi
}

handle_camera_toggle() {
    . /etc/acpi/lib/camera.sh
    if [ -e $CAM_CTL ]; then
	toggle_camera
	show_camera
    else
	notify error 'Camera unavailable'
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
	notify wireless 'Wireless ...'
	/etc/acpi/actions/wireless.sh on
	show_wireless
	;;
    00000011)
	notify wireless 'Wireless ...'
	/etc/acpi/actions/wireless.sh off
	show_wireless
	;;
    # Fn+F6
    00000012)
	if [ "${FnF6:-NONE}" != 'NONE' ]; then
	    $FnF6
	fi
	;;
    # Fn+F7 -- mute/unmute speakers
    00000013)
	if [ "${FnF7:-handle_mute_toggle}" != 'NONE' ]; then
	    ${FnF7:-handle_mute_toggle}
	fi
	;;
    # Fn+F8 -- decrease volume
    00000014)
	if [ "${FnF8:-handle_volume_down}" != 'NONE' ]; then
	    ${FnF8:-handle_volume_down}
	fi
	;;
    # Fn+F9 -- increase volume
    00000015)
	if [ "${FnF9:-handle_volume_up}" != 'NONE' ]; then
	    ${FnF9:-handle_volume_up}
	fi
	;;
	# F+F5 -- toggle vga
	0000003[012])
	/etc/acpi/actions/vga-toggle.sh
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
