
configureSound() {

    [ "$SOUND_LABEL" ] || {
	 SOUND_LABEL="$($AMIXER | grep -B1 pvolume |
			sed -r "s/^(.*'([^']+)'.*|[^']+())$/\\2/")"
    }

    [ "$SOUND_SWITCH" ] || {
	 SOUND_SWITCH="$($AMIXER | grep -B1 pswitch |
			sed -r "s/^(.*'([^']+)'.*|[^']+())$/\\2/")"
    }

    [ "$SOUND_SWITCH_EXCLUSIVE" ] || {
	 SOUND_SWITCH_EXCLUSIVE="$($AMIXER | grep -B1 ': pswitch$' |
				sed -r "s/^(.*'([^']+)'.*|[^']+())$/\\2/")"
    }

}
