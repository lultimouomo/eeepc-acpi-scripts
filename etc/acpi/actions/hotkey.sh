#!/bin/sh

# do nothing if package is removed
PKG=eeepc-acpi-scripts
FUNC_LIB=/usr/share/$PKG/functions.sh
DEFAULT=/etc/default/$PKG
[ -e "$FUNC_LIB" ] || exit 0

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
    if /etc/acpi/actions/wireless.sh detect; then
	status=Off
    else
	status=On
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
    if [ -e "$BT_CTL" ] || [ "$BLUETOOTH_FALLBACK_TO_HCITOOL" = "yes" ]; then
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
    if [ -e "$CAM_CTL" ]; then
	toggle_camera
	show_camera
    else
	notify error 'Camera unavailable'
    fi
}

show_brightness() {
    # final digit of ACPI code is brightness level in hex
    level=$((0x$code & 0xF))
    # convert hex digit to percent
    percent=$(((100 * $level + 8) / 15))
    notify brightness "Brightness $percent%" fast
}

handle_shengine() {
    . /etc/acpi/lib/shengine.sh
    handle_shengine "$@"
}

handle_touchpad_toggle() {
    . /etc/acpi/lib/touchpad.sh
    toggle_touchpad &&
	notify touchpad 'Touchpad on' ||
	notify touchpad 'Touchpad off'
}

handle_gsm_toggle() {
    /etc/acpi/actions/gsm.sh toggle
    if /etc/acpi/actions/gsm.sh detect; then
        notify gsm "GSM off"
    else
        notify gsm "GSM on"
    fi
}


case $code in
    # Fn + key:
    # <700/900-series key>/<1000-series key> - function
    # "--" = not available

    # F1/F1 - suspend
    # (not a hotkey, not handled here)

    # F2/F2 - toggle wireless
    0000001[01])
	notify wireless 'Wireless ...'
	if grep -q '^H.*\brfkill\b' /proc/bus/input/devices; then
	  :
	else
	  /etc/acpi/actions/wireless.sh toggle
	fi
	show_wireless
	;;

    # --/F3 - touchpad toggle
    00000037)
	if [ "${FnF_TOUCHPAD}" != 'NONE' ]; then
	    ${FnF_BACKLIGHTOFF:-handle_touchpad_toggle}
	fi
	;;

    # --/F4 - resolution change
    00000038)
	if [ "${FnF_RESCHANGE}" != 'NONE' ]; then
	    $FnF_RESCHANGE
	fi
	;;

    # F3/F5 - decrease brightness
    # F4/F6 - increase brightness
    0000002?)
	# actual brightness change is handled in hardware
	if [ "x$ENABLE_OSD_BRIGHTNESS" != "xno" ]; then
	  show_brightness
	fi
	;;

    # --/F7 - backlight off
    00000016)
	if [ "${FnF_BACKLIGHTOFF}" != 'NONE' ]; then
	    ${FnF_BACKLIGHTOFF:-handle_blank_screen}
	fi
	;;

    # F5/F8 - toggle VGA
    0000003[012])
	/etc/acpi/actions/vga-toggle.sh
	;;

    # F6/F9 - 'task manager' key
    00000012)
	if [ "${FnF_TASKMGR:-NONE}" != 'NONE' ]; then
	    $FnF_TASKMGR
	fi
	;;

    # F7/F10 - mute/unmute speakers
    00000013)
	if [ "${FnF_MUTE}" != 'NONE' ]; then
	    ${FnF_MUTE:-handle_mute_toggle}
	fi
	;;

    # F8/F11 - decrease volume
    00000014)
	if [ "${FnF_VOLUMEDOWN}" != 'NONE' ]; then
	    ${FnF_VOLUMEDOWN:-handle_volume_down}
	fi
	;;

    # F9/F12 - increase volume
    00000015)
	if [ "${FnF_VOLUMEUP}" != 'NONE' ]; then
	    ${FnF_VOLUMEUP:-handle_volume_up}
	fi
	;;

    # --/Space - SHE management
    # (ACPI event code not known)

    # Silver keys, left to right

    # Soft button 1
    0000001a)
	if [ "${SOFTBTN1_ACTION}" != 'NONE' ]; then
	    ${SOFTBTN1_ACTION:-handle_blank_screen}
	fi
	;;

    # Soft button 2
    0000001b)
	if [ "${SOFTBTN2_ACTION}" != 'NONE' ]; then
	    ${SOFTBTN2_ACTION}
	fi
	;;

    # Soft button 3
    0000001c)
	if [ "${SOFTBTN3_ACTION}" != 'NONE' ]; then
	    ${SOFTBTN3_ACTION:-handle_camera_toggle}
	fi
	;;

    # Soft button 4
    0000001d)
	if [ "${SOFTBTN4_ACTION}" != 'NONE' ]; then
	    ${SOFTBTN4_ACTION:-handle_bluetooth_toggle}
	fi
	;;

esac
