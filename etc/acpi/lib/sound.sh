
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

    [ "$SOUND_VOLUME_STEP" ] || {
	 case "$(grep ^00-00 /proc/asound/pcm 2>/dev/null)" in
	     *ALC269*)	SOUND_VOLUME_STEP=3.125%; ;;
	     *)		SOUND_VOLUME_STEP=2%; ;;
	 esac
    }

}
