#!/bin/sh
#
# src/buildah.sh
# ==============
#
# Copying
# -------
#
# Copyright (c) 2020 alpine-guix authors.
#
# This file is part of the *alpine-guix* project.
#
# alpine-guix is a free software project. You can redistribute it and/or
# modify if under the terms of the MIT License.
#
# This software project is distributed *as is*, WITHOUT WARRANTY OF ANY
# KIND; including but not limited to the WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE and NONINFRINGEMENT.
#
# You should have received a copy of the MIT License along with
# alpine-guix. If not, see <http://opensource.org/licenses/MIT>.
#

# Layer 0: Welcome
# ----------------

cat << "EOF"

    ░░░                                     ░░░
    ░░▒▒░░░░░░░░░               ░░░░░░░░░▒▒░░
     ░░▒▒▒▒▒░░░░░░░           ░░░░░░░▒▒▒▒▒░
         ░▒▒▒░░▒▒▒▒▒         ░░░░░░░▒▒░
               ░▒▒▒▒░       ░░░░░░
                ▒▒▒▒▒      ░░░░░░
                 ▒▒▒▒▒     ░░░░░
                 ░▒▒▒▒▒   ░░░░░
                  ▒▒▒▒▒   ░░░░░
                   ▒▒▒▒▒ ░░░░░
                   ░▒▒▒▒▒░░░░░
                    ▒▒▒▒▒▒░░░
                     ▒▒▒▒▒▒░
     _____ _   _ _    _    _____       _
    / ____| \ | | |  | |  / ____|     (_)
   | |  __|  \| | |  | | | |  __ _   _ ___  __
   | | |_ | . ' | |  | | | | |_ | | | | \ \/ /
   | |__| | |\  | |__| | | |__| | |_| | |>  <
    \_____|_| \_|\____/   \_____|\__,_|_/_/\_\

EOF


# Layer 1: Build
# --------------

ctnr=$(buildah from alpine:latest)


GUIX_VERSION="1.0.1"
GUIX_ARCH="x86_64"
GUIX_OS="linux"
GUIX_ARCHIVE="guix-binary-${GUIX_VERSION}.${GUIX_ARCH}-${GUIX_OS}.tar.xz"
GUIX_URL="https://ftp.gnu.org/gnu/guix/${GUIX_ARCHIVE}"
GUIX_OPENPGP_KEY_ID="3CE464558A84FDC69DB40CFB090B11993D9AEBB5"
GUIX_PROFILE="/root/.config/guix/current"
GUIX_SYS_PROFILE="/var/guix/profiles/per-user/root/current-guix"
GUIX_BUILD_GRP="guixbuild"
GUIX_BUILD_USER="guixbuilder"
GUIX_MAX_JOBS=10
GUIX_OPTS="--verbose --verbosity=2"
GUIX_SVCNAME="guix-daemon"

GPG_KEYSERVER="pool.sks-keyservers.net"
GPG_OPTS="--no-greeting"

WGET_OPTS="--no-verbose --show-progress --progress=bar:force"

ENTRY_D=/root
PREFIX_D=/usr/local
PROFILE_D=/etc/profile.d
INIT_D=/etc/init.d
WORK_D=/tmp


# Try to run given command and exit on failure.
# We basically don't want to continue any further when a command fails.
try() { ${@} || exit ${?}; }


# System
# ^^^^^^

try buildah run "${ctnr}" -- apk add --no-cache ca-certificates gnupg openrc wget

# OpenRC: Disable login consoles.
try buildah run "${ctnr}" -- sed -i '/^tty[0-9]\+:.*:\(re\)\?spawn:/d' /etc/inittab
# OpenRC: Define subsystem.
try buildah run "${ctnr}" -- sed -i 's/^#\?rc_sys=".*"/rc_sys="docker"/' /etc/rc.conf

# Set USER environment variable so Guix can properly set the path to the user's
# profile.
#
# See: https://issues.guix.info/issue/39195
try buildah config --env USER="root" "${ctnr}"


# Guix
# ^^^^

# Installation
# """"""""""""

try buildah run "${ctnr}" -- wget ${WGET_OPTS} "${GUIX_URL}.sig" --output-document="${WORK_D}/${GUIX_ARCHIVE}.sig"
try buildah run "${ctnr}" -- wget ${WGET_OPTS} "${GUIX_URL}" --output-document="${WORK_D}/${GUIX_ARCHIVE}"

try buildah run "${ctnr}" -- gpg ${GPG_OPTS} --keyserver "${GPG_KEYSERVER}" --recv-keys "${GUIX_OPENPGP_KEY_ID}"
try buildah run "${ctnr}" -- gpg ${GPG_OPTS} --verify "${WORK_D}/${GUIX_ARCHIVE}.sig"

try buildah run "${ctnr}" -- tar -xJvf "${WORK_D}/${GUIX_ARCHIVE}" -C /
buildah run "${ctnr}" -- rm -f "${WORK_D}/${GUIX_ARCHIVE}"
buildah run "${ctnr}" -- rm -f "${WORK_D}/${GUIX_ARCHIVE}.sig"


# Environment Setup
# """""""""""""""""

# Setup Guix profile.
try buildah run "${ctnr}" -- mkdir --parents "$(dirname "${GUIX_PROFILE}")"
try buildah run "${ctnr}" -- ln -s "${GUIX_SYS_PROFILE}" "${GUIX_PROFILE}"
try buildah copy "${ctnr}" ./scripts/guix.sh "${PROFILE_D}/guix.sh"

# Enable GNU Guix substitutions.
buildah run "${ctnr}" -- sh -c "'${GUIX_PROFILE}/bin/guix' archive --authorize < '${GUIX_PROFILE}/share/guix/ci.guix.gnu.org.pub'" \
    || exit ${?}

# Make Guix command available system wide (in case profile is not loaded).
try buildah run "${ctnr}" -- mkdir --parents "${PREFIX_D}/bin"
try buildah run "${ctnr}" -- ln -s "${GUIX_SYS_PROFILE}/bin/guix" "${PREFIX_D}/bin/guix"

# Create build users.
try buildah run "${ctnr}" -- addgroup -S "${GUIX_BUILD_GRP}"
for i in $(seq -w 1 ${GUIX_MAX_JOBS})
do
    try buildah run "${ctnr}" -- adduser -S                                     \
            -g "${GUIX_BUILD_GRP}" -G "${GUIX_BUILD_GRP}"                       \
            -h /var/empty/guix -s "$(command -v nologin)"                       \
            "${GUIX_BUILD_USER}${i}"
done

# Install init script.
try buildah copy "${ctnr}" ./scripts/guix-daemon "${INIT_D}/${GUIX_SVCNAME}"
try buildah run "${ctnr}" -- chmod 0755 "${INIT_D}/${GUIX_SVCNAME}"
try buildah run "${ctnr}" -- rc-update add "${GUIX_SVCNAME}" default


# Packages Upgrade
# """"""""""""""""

buildah run "${ctnr}" -- sh -c "source '${GUIX_PROFILE}/etc/profile'
'${GUIX_PROFILE}/bin/guix-daemon' --build-users-group='${GUIX_BUILD_GRP}' --disable-chroot &
'${GUIX_PROFILE}/bin/guix' pull ${GUIX_OPTS}                                    \
    && '${GUIX_PROFILE}/bin/guix' package ${GUIX_OPTS} --upgrade                \
    && '${GUIX_PROFILE}/bin/guix' gc                                            \
    && '${GUIX_PROFILE}/bin/guix' gc --optimize
" || exit ${?}


# Image Finalization
# ^^^^^^^^^^^^^^^^^^

try buildah run "${ctnr}" -- apk del --no-cache gnupg wget

buildah config --workingdir "${ENTRY_D}" "${ctnr}"
buildah config --cmd "/sbin/init" "${ctnr}"
buildah commit --squash "${ctnr}" "x237net/alpine-guix"
