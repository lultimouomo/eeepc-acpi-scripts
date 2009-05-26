# a shell library for handling Asus EeePC "Super Hybrid Engine"
#
# to be sourced

SHENGINE_CTL=/sys/devices/platform/eeepc/cpufv
SHENGINE_LIMIT="$(cat "$SHENGINE_CTL" 2>/dev/null || :)"
SHENGINE_LIMIT=$(( ${SHENGINE_LIMIT:-768} >> 8 ))

SHENGINE_CONFIG=/var/lib/eeepc-acpi-scripts/cpufv
SHENGINE_SETTING="$(cat "$SHENGINE_CONFIG" 2>/dev/null || :)"

get_shengine()
{
    if [ "$SHENGINE_SETTING" = auto -a "$1" = '' ]; then
	echo 255
    elif [ -e "$SHENGINE_CTL" ]; then
        echo $(( $(cat "$SHENGINE_CTL") & 0xFF ))
    else
	echo 3
    fi
}

set_shengine()
{
    if [ -e "$SHENGINE_CTL" -a "$SHENGINE_SETTING" = auto ]; then
	echo "$1" > "$SHENGINE_CTL"
    fi
}

cycle_shengine()
{
    if [ -e "$SHENGINE_CTL" ]; then
	SHENGINE_CLOCKING=$(get_shengine)
	if [ "$SHENGINE_SETTING" = auto ]; then
	    SHENGINE_CLOCKING=0
	    SHENGINE_SETTING=manual
	    echo manual >"$SHENGINE_CONFIG"
	else
	    SHENGINE_CLOCKING=$(( ($SHENGINE_CLOCKING + 1) % $SHENGINE_LIMIT))
	    if [ "$SHENGINE_CLOCKING" = 0 ]; then
		if [ "$(cat /sys/class/power_supply/AC0/online 2>/dev/null || echo 1)" != 0 ]; then
		    SHENGINE_CLOCKING="$PWR_CLOCK_AC"
		else
		    SHENGINE_CLOCKING="$PWR_CLOCK_BATTERY"
		fi
		if [ "$SHENGINE_CLOCKING:+1" ]; then
		    SHENGINE_SETTING=auto
		    echo auto >"$SHENGINE_CONFIG"
		fi
	    fi
	fi
	echo "${SHENGINE_CLOCKING:-0}" > "$SHENGINE_CTL"
    fi
}
