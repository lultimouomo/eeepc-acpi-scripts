configureSoundFilter() {
  $AMIXER |
  grep -B1 "$1" |
  sed -r "s/^(.*'([^']+)'.*|[^']+())$/\\2/; /^$/ d"
}

configureSound() {

    [ "$SOUND_LABEL" ] || {
	 SOUND_LABEL="$(configureSoundFilter pvolume)"
    }

    [ "$SOUND_SWITCH" ] || {
	 SOUND_SWITCH="$(configureSoundFilter pswitch)"
    }

    [ "$SOUND_SWITCH_EXCLUSIVE" ] || {
	 SOUND_SWITCH_EXCLUSIVE="$(configureSoundFilter ': pswitch$')"
    }

    [ "$SOUND_VOLUME_STEP" ] || {
	 case "$(grep ^00-00 /proc/asound/pcm 2>/dev/null)" in
	     *ALC269*)	SOUND_VOLUME_STEP=3.125%; ;;
	     *)		SOUND_VOLUME_STEP=2%; ;;
	 esac
    }

}
