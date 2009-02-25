# Parse amixer output for a regexp (first parameter).
# Some controls are blacklisted; for this, we use a set of fixed strings in
# /etc/acpi/lib/eeepc-amixer-blacklist. (No wildcards or regexps.)

PKG=eeepc-acpi-scripts
DEFAULT=/etc/default/$PKG
SOUND_FILE=/var/cache/$PKG/sound
AMIXER=/usr/bin/amixer

[ -e "$SOUND_FILE" ] && . "$SOUND_FILE"
[ -e "$DEFAULT" ] && . "$DEFAULT"
[ -x "$AMIXER" ] || exit 1

[ "$SOUND_LABEL" = '' ] && SOUND_LABEL="$DEF_SOUND_LABEL"
[ "$SOUND_SWITCH" = '' ] && SOUND_SWITCH="$DEF_SOUND_SWITCH"
[ "$SOUND_SWITCH_EXCLUSIVE" = '' ] && SOUND_SWITCH_EXCLUSIVE="$DEF_SOUND_SWITCH_EXCLUSIVE"
[ "$SOUND_VOLUME_STEP" = '' ] && SOUND_VOLUME_STEP="$DEF_SOUND_VOLUME_STEP"

configureSoundFilter() {
  $AMIXER |
  grep -B1 "$1" |
  sed -r "s/^(.*'([^']+)'.*|[^']+())$/\\2/; /^$/ d" |
  grep -ivFf /etc/acpi/lib/eeepc-amixer-blacklist
}

# Defaults
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
#	     *ALC269*|*ALC662*)
#			SOUND_VOLUME_STEP=3.125%; ;;
	     *)		SOUND_VOLUME_STEP=3.125%; ;;
	 esac
    }

}
