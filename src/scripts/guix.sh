# /etc/profile.d/guix.sh
# ======================
#
# Load Guix profile into the user's shell environment.

# Guix pull profile.
_GUIX_PROFILE="${HOME}/.config/guix/current"
[ -L "${_GUIX_PROFILE}" ] \
    && export PATH="${_GUIX_PROFILE}/bin${PATH:+:}${PATH}"

# User's default profile.
GUIX_PROFILE="${HOME}/.guix-profile"
GUIX_LOCPATH="${GUIX_PROFILE}/lib/locale"

[ -L "${GUIX_PROFILE}" ] || return
export GUIX_PROFILE GUIX_LOCPATH

eval $(guix package --search-paths=prefix 2> /dev/null)
export XDG_DATA_DIRS="${GUIX_PROFILE}/share${XDG_DATA_DIRS:+:}${XDG_DATA_DIRS}"
