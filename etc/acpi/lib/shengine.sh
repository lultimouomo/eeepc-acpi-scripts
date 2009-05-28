# a shell library for handling Asus EeePC "Super Hybrid Engine"
#
# to be sourced

SHENGINE_CTL=/sys/devices/platform/eeepc/cpufv
SHENGINE_LIMIT="$(cat "$SHENGINE_CTL" 2>/dev/null)"
SHENGINE_LIMIT=$(( ${SHENGINE_LIMIT:-768} >> 8 ))

get_shengine()
{
    if [ -e "$SHENGINE_CTL" ]; then
        return $(( $(cat "$SHENGINE_CTL") & 0xFF ))
    fi
    return 3
}

cycle_shengine()
{
    if [ -e "$SHENGINE_CTL" ]; then
	get_shengine
	echo $(( ($? + 1) % $SHENGINE_LIMIT)) > "$SHENGINE_CTL"
    fi
    get_shengine
}
