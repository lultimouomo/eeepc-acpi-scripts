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
    if [ -e $BT_CTL ] || [ "$BLUETOOTH_FALLBACK_TO_HCITOOL" = "yes" ]; then
	toggle_bluetooth
	show_bluetooth
    else
	notify error 'Bluetooth unavailable'
    fi
}

handle_shengine() {
    . /etc/acpi/lib/shengine.sh
    if [ -e "$SHENGINE_CTL" ]; then
	if [ "$1" = '' ]; then
	    cycle_shengine
	else
	    set_shengine "$1"
	fi
	if [ "$2" != '' ]; then return; fi
	case $(get_shengine) in
	    0) notify super_hybrid_engine 'S. H. Engine: Performance'; ;;
	    1) notify super_hybrid_engine 'S. H. Engine: Standard'; ;;
	    2) notify super_hybrid_engine 'S. H. Engine: Power-saving'; ;;
	    255) notify super_hybrid_engine 'S. H. Engine: Automatic'; ;;
	    *) notify error 'S. H. Engine unavailable'
	esac
    else
	notify error 'S. H. Engine unavailable'
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

show_brightness() {
    # final digit of ACPI code is brightness level in hex
    level=$((0x$code & 0xF))
    # convert hex digit to percent
    percent=$(((100 * $level + 8) / 15))
    notify brightness "Brightness $percent%" fast
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
	;;

    # --/F4 - resolution change
    00000038)
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
	if [ "${FnF_BACKLIGHTOFF:-handle_blank_screen}" != 'NONE' ]; then
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
	if [ "${FnF_MUTE:-handle_mute_toggle}" != 'NONE' ]; then
	    ${FnF_MUTE:-handle_mute_toggle}
	fi
	;;

    # F8/F11 - decrease volume
    00000014)
	if [ "${FnF_VOLUMEDOWN:-handle_volume_down}" != 'NONE' ]; then
	    ${FnF_VOLUMEDOWN:-handle_volume_down}
	fi
	;;

    # F9/F12 - increase volume
    00000015)
	if [ "${FnF_VOLUMEUP:-handle_volume_up}" != 'NONE' ]; then
	    ${FnF_VOLUMEUP:-handle_volume_up}
	fi
	;;

    # --/Space - SHE management
    # (ACPI event code not known)

    # Silver keys, left to right

    # Soft button 1
    0000001a)
	if [ "${SOFTBTN1_ACTION:-handle_blank_screen}" != 'NONE' ]; then
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
	if [ "${SOFTBTN3_ACTION:-handle_camera_toggle}" != 'NONE' ]; then
	    ${SOFTBTN3_ACTION:-handle_camera_toggle}
	fi
	;;

    # Soft button 4
    0000001d)
	if [ "${SOFTBTN4_ACTION:-handle_bluetooth_toggle}" != 'NONE' ]; then
	    ${SOFTBTN4_ACTION:-handle_bluetooth_toggle}
	fi
	;;

esac
