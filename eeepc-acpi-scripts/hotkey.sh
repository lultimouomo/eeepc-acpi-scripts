#!/bin/sh

test -d /sys/bus/platform/devices/eeepc || exit 0
# do nothing if package is removed
PKG=eeepc-acpi-scripts
PKG_DIR=/usr/share/acpi-support/$PKG
FUNC_LIB=$PKG_DIR/lib/functions.sh
DEFAULT=/etc/default/$PKG
[ -e "$FUNC_LIB" ] || exit 0

case $(runlevel) in
    *0|*6)
	exit 0
	;;
esac

BACKLIGHT=/sys/class/backlight/eeepc/brightness
if [ -e "$DEFAULT" ]; then . "$DEFAULT"; fi
. $FUNC_LIB

. $PKG_DIR/lib/notify.sh
code=$3
value=$(test "x$1" = x- && cat "$BACKLIGHT" || echo "0x$3")

# In case keys are doubly-reported as hotkey and something else.
# It's random (and irrelevant) which is seen first.
acpi=
acpiwrite=
ACPITEST=/lib/init/rw/eeepc-acpi-scripts.acpi-ignore
case "$code" in
    # Soft buttons 3 & 4 and Fn-Space/SHE are special.
    # They're always reported as hotkeys.
    # This will probably break when button events are added for these keys.
    0000001[cd]|00000039)
	;;
    *)
	if test -f "$ACPITEST"; then
	    read acpi <"$ACPITEST"
	else
	    acpiwrite=$(test "x$1" = x- && echo hotkey || echo -)
	fi
	test "$1" = "$acpi" && exit 0
	;;
esac

seen_hotkey() { test "$acpi" = button; }

handle_mute_toggle() {
    $PKG_DIR/volume.sh toggle
}

handle_volume_up() {
    $PKG_DIR/volume.sh up
}

handle_volume_down() {
    $PKG_DIR/volume.sh down
}

show_wireless() {
    if $PKG_DIR/wireless.sh detect; then
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
    . $PKG_DIR/lib/bluetooth.sh
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
    . $PKG_DIR/lib/camera.sh
    if [ -e "$CAM_CTL" ]; then
	toggle_camera
	show_camera
    else
	notify error 'Camera unavailable'
    fi
}

show_brightness() {
    # final digit of ACPI code is brightness level in hex
    level=$(($value & 0xF))
    # convert hex digit to percent
    percent=$(((100 * $level + 8) / 15))
    notify brightness "Brightness $percent%" fast
}

handle_shengine() {
    . $PKG_DIR/lib/shengine.sh
    handle_shengine "$@"
}

handle_touchpad_toggle() {
    . $PKG_DIR/lib/touchpad.sh
    toggle_touchpad
    case "$?" in
	0)
	    notify touchpad 'Touchpad on'
	    ;;
	1)
	    notify touchpad 'Touchpad off'
	    ;;
    esac
}

handle_vga_toggle() {
    $PKG_DIR/vga-toggle.sh
}

handle_gsm_toggle() {
    $PKG_DIR/gsm.sh toggle
    if $PKG_DIR/gsm.sh detect; then
        notify gsm "GSM off"
    else
        notify gsm "GSM on"
    fi
}

# Handle events which we're handling differently on different models
case $(cat /sys/class/dmi/id/product_name) in
    [79]*|1000H)
	case $code in
	    ZOOM)
		code=0000001b # soft button 2
		;;
	esac
	;;
    *)
	case $code in
	    ZOOM)
		code=00000038 # Fn-F4
		;;
	esac
	;;
esac

case $code in
    # Fn + key:
    # <700/900-series key>/<1000-series key> - function
    # "--" = not available

    # F1/F1 - suspend
    # (not a hotkey, not handled here)

    # F2/F2 - toggle wireless
    0000001[01]|WLAN)
	notify wireless 'Wireless ...'
	if grep -q '^H.*\brfkill\b' /proc/bus/input/devices; then
	  :
	else
	  $PKG_DIR/wireless.sh toggle
	fi
	show_wireless
        if ! $PKG_DIR/wireless.sh detect; then
            wakeup_wicd
        fi
	;;

    # --/F3 - touchpad toggle
    00000037)
	if [ "${FnF_TOUCHPAD}" != 'NONE' ]; then
	    ${FnF_TOUCHPAD:-handle_touchpad_toggle}
	fi
	;;

    # --/F4 - resolution change
    00000038) # ZOOM
	if [ "${FnF_RESCHANGE}" != 'NONE' ]; then
	    $FnF_RESCHANGE
	fi
	;;

    # F3/F5 - decrease brightness
    # F4/F6 - increase brightness
    0000002?|BRTDN|BRTUP)
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
    0000003[012]|VMOD)
	if [ "${FnF_VGATOGGLE}" != 'NONE' ]; then
	    ${FnF_VGATOGGLE:-handle_vga_toggle}
	fi
	;;

    # F6/F9 - 'task manager' key
    00000012|PROG1)
	if [ "${FnF_TASKMGR:-NONE}" != 'NONE' ]; then
	    $FnF_TASKMGR
	fi
	;;

    # F7/F10 - mute/unmute speakers
    00000013|MUTE)
	if [ "${FnF_MUTE}" != 'NONE' ]; then
	    ${FnF_MUTE:-handle_mute_toggle}
	fi
	;;

    # F8/F11 - decrease volume
    00000014|VOLDN)
	if [ "${FnF_VOLUMEDOWN}" != 'NONE' ]; then
	    ${FnF_VOLUMEDOWN:-handle_volume_down}
	fi
	;;

    # F9/F12 - increase volume
    00000015|VOLUP)
	if [ "${FnF_VOLUMEUP}" != 'NONE' ]; then
	    ${FnF_VOLUMEUP:-handle_volume_up}
	fi
	;;

    # --/Space - SHE management
    # See "SHE button" below

    # Silver keys, left to right

    # Soft button 1
    0000001a|SCRNLCK)
	if [ "${SOFTBTN1_ACTION}" != 'NONE' ]; then
	    ${SOFTBTN1_ACTION:-handle_blank_screen}
	fi
	;;

    # Soft button 2
    0000001b) # ZOOM
	if [ "${SOFTBTN2_ACTION}" != 'NONE' ]; then
	    ${SOFTBTN2_ACTION}
	fi
	;;

    # Soft button 3
    0000001c)
	if [ "${SOFTBTN3_ACTION}" != 'NONE' ]; then
	    ${SOFTBTN3_ACTION:-handle_camera_toggle}
	fi
	acpiwrite=
	;;

    # Soft button 4
    0000001d)
	if [ "${SOFTBTN4_ACTION}" != 'NONE' ]; then
	    ${SOFTBTN4_ACTION:-handle_bluetooth_toggle}
	fi
	acpiwrite=
	;;

    # SHE button
    00000039)
	if [ "${SOFTBTNSHE_ACTION}" != 'NONE' ]; then
	    ${SOFTBTNSHE_ACTION:-handle_shengine}
	fi
	acpiwrite=
	;;

esac

test "$acpiwrite" = '' || echo "$acpiwrite" >"$ACPITEST"
