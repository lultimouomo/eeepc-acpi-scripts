#! /bin/sh

# Load pciehp if required.
# There are three recognised cases:
# - kernel 2.6.26 & older: two parameters required
# - kernel 2.6.27 & .28  : one of those parameters has been removed
# - kernel 2.6.29 & newer: hotplugging is handled in eeepc-laptop

KERNEL="`uname -r`"
case "$KERNEL" in
  2.6.*)
    KERNEL="`echo $KERNEL | sed -re 's/^([0-9]+\.){2}([0-9]+).*$/\2/'`"
    if [ "$KERNEL" -lt 27 ]; then
      # 2.6.26 and older
      exec modprobe --ignore-install pciehp pciehp_force=1 pciehp_slot_with_bus=1
    elif [ "$KERNEL" -lt 29 ]; then
      # 2.6.27 and 2.6.28
      exec modprobe --ignore-install pciehp pciehp_force=1
    fi
    ;;
esac

exit 0
