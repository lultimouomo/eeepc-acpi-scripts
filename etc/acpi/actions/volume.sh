#!/bin/sh

# Volume controls

# do nothing if package is removed
PKG=eeepc-acpi-scripts
FUNC_LIB=/usr/share/$PKG/functions.sh
DEFAULT=/etc/default/$PKG
[ -e $FUNC_LIB ] || exit 0

if [ -e "$DEFAULT" ]; then . "$DEFAULT"; fi
. $FUNC_LIB
. /etc/acpi/lib/notify.sh
action=$1

usage() {
    cat <<EOF >&2
Usage: $0 up|down|toggle
EOF
    exit 1
}

AMIXER=/usr/bin/amixer

if ! [ -x $AMIXER ]; then
    echo "$AMIXER not available" >&2
    exit 1
fi

show_muteness() {
    status=$($AMIXER get $VOLUME_LABEL | sed -n '/%/{s/.*\[\(on\|off\)\].*/\u\1/p;q}')
    notify audio "Audio $status"
}

show_volume() {
    percent=$($AMIXER get $VOLUME_LABEL | sed -n '/%/{s/.*\[\(.*\)%\].*/\1/p;q}')
    notify audio "Volume $percent"
}

case "$action" in
    toggle)
        # muting $VOLUME_LABEL affects the headphone jack but not the speakers
        $AMIXER -q set $VOLUME_LABEL toggle
        # muting $HEADPHONE_LABEL affects the speakers but not the headphone jack
        $AMIXER -q set $HEADPHONE_LABEL toggle
        show_muteness
        ;;
    down)
        amixer -q set $VOLUME_LABEL 2- unmute
        amixer -q set $HEADPHONE_LABEL unmute
        show_volume
        ;;
    up)
        amixer -q set $VOLUME_LABEL 2+ unmute
        amixer -q set $HEADPHONE_LABEL unmute
        show_volume
        ;;
    *)
        usage
        ;;
esac
