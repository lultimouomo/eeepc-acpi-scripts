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
. /etc/acpi/lib/sound.sh
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

configureSound

show_muteness() {
    local label msg status all_equal=1 current
    for label in $SOUND_SWITCH; do
	current=$($AMIXER get $label |
		    sed -n 's/.*\[\(on\|off\)\].*/\1/;ta;d;:a;p')
	case "$(echo "$current")" in
	    on*off*) current='on[L]'; ;;
	    off*on*) current='on[R]'; ;;
	    on*)     current='on'; ;;
	    off*)    current='off'; ;;
	esac
	[ "$status" ] || status="$current"
	[ "$status" = "$current" ] || all_equal=
	msg="$msg $current ($label)"
    done
    if [ "$all_equal" ]; then
	msg=" $status"
    fi
    notify audio "Audio$msg"
}

show_volume() {
    local label msg percent all_equal=1 current
    for label in $SOUND_LABEL; do
	current=$($AMIXER get $label |
		    sed -n '/%/{s/.*\[\(.*\)%\].*/\1/p;q}')
	[ "$percent" ] || percent="$current"
	[ "$percent" = "$current" ] || all_equal=
	msg="$msg $current% ($label)"
	if [ "$DETAILED_SOUND_INFO" != 'yes' ]; then
	    break
	fi
    done
    if [ "$all_equal" ]; then
	msg="$percent%"
    fi
    notify audio "Volume $msg" fast
}

# cope with control names which contain spaces
IFS='
'

case "$action" in
    toggle)
        for label in $SOUND_SWITCH; do
            $AMIXER -q set $label toggle
        done
        show_muteness
        ;;
    down)
        for label in $SOUND_LABEL $SOUND_SWITCH_EXCLUSIVE; do
            $AMIXER -q set $label 2%- unmute
        done
        show_volume
        ;;
    up)
        for label in $SOUND_LABEL $SOUND_SWITCH_EXCLUSIVE; do
            $AMIXER -q set $label 2%+ unmute
        done
        show_volume
        ;;
    *)
        usage
        ;;
esac
