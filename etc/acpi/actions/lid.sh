#!/bin/sh

[ -e /usr/share/acpi-support/policy-funcs ] || exit 0

. /usr/share/acpi-support/policy-funcs


if [ `CheckPolicy` = 0 ] ; then
	exit 0
fi

[ -e /etc/default/eeepc-acpi-scripts ] || exit 0
. /etc/default/eeepc-acpi-scripts

case "$LID_CLOSE_ACTION" in
    nothing)
	exit 0
    ;;
    suspend|"")
	[ -e /etc/acpi/actions/suspend.sh ] || exit 0
	. /etc/acpi/actions/suspend.sh
    ;;
    *)
	$LID_CLOSE_ACTION
    ;;
esac
