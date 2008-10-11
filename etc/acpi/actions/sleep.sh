#!/bin/sh

[ -e /usr/share/acpi-support/policy-funcs ] || exit 0

. /usr/share/acpi-support/policy-funcs

# If powersaved is running, let it process the acpi event
if pidof powersaved; then
	exit 0
fi

if [ `CheckPolicy` = 0 ] ; then
	exit 0
fi

[ -e /etc/acpi/actions/suspend.sh ] || exit 0

. /etc/acpi/actions/suspend.sh
