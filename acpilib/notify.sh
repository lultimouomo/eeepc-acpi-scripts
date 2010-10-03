# eeepc-acpi-scripts notification library
#
# this file is to be sourced

notify() {
    CATEGORY=$1
    MSG=$2
    ICON_bluetooth=" "
    ICON_super_hybrid_engine=" "
    ICON_error=" "
    ICON_camera=" "
    ICON_touchpad=" "
    ICON_gsm=" "

    if [ -n "$4" -o \( -n "$3" -a "$3" != 'fast' \) ]; then
	echo "usage: notify 'category' 'message text' [fast]" > /dev/stderr
	return 1
    fi
    echo "$MSG"  # for /var/log/acpid

    if [ ! -S /tmp/.X11-unix/X0 ]; then
        # echo's behaviour wrt "\r" is shell-dependent
	printf "$MSG\r\n" > /dev/console
	return
    fi

    if [ "x$ENABLE_OSD" = "xno" ]; then
        return
    fi

    if [ -x /usr/bin/notify-send ]; then
        notify-send -i $ICON_"$1" "$2"
    else
        echo "Please install libnotify-bin" > /dev/stderr
        return 1
    fi
}

