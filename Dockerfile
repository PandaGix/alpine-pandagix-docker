# src/Dockerfile
# ==============
# Copyright (c) 2020 alpine-guix authors.
# Copyright (c) 2021 BambooGeek@PandaGix
# This file is part of the *alpine-guix* project.
# alpine-guix is a free software project. You can redistribute it and/or
# modify if under the terms of the MIT License.
# This software project is distributed *as is*, WITHOUT WARRANTY OF ANY
# KIND; including but not limited to the WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE and NONINFRINGEMENT.
# You should have received a copy of the MIT License along with
# alpine-guix. If not, see <http://opensource.org/licenses/MIT>.

# Layer 0: Welcome
# ----------------

# Layer 1: Build
# --------------

FROM pandagix/alpine-pandagix-docker:5.10.16-linux AS build

ARG GUIX_VERSION=1.2.0
ARG GUIX_ARCH="x86_64"
ARG GUIX_OS="linux"
ARG GUIX_ARCHIVE="guix-binary-${GUIX_VERSION}.${GUIX_ARCH}-${GUIX_OS}.tar.xz"
ARG GUIX_URL="https://ftp.gnu.org/gnu/guix/${GUIX_ARCHIVE}"
ARG GUIX_OPENPGP_KEY_ID="3CE464558A84FDC69DB40CFB090B11993D9AEBB5"
ARG GUIX_PROFILE="/root/.config/guix/current"
ARG GUIX_CONFIG="/root/.config/guix"
ARG GUIX_SYS_PROFILE="/var/guix/profiles/per-user/root/current-guix"
ARG GUIX_BUILD_GRP="guixbuild"
ARG GUIX_BUILD_USER="guixbuilder"
ARG GUIX_MAX_JOBS=10
ARG GUIX_OPTS="--verbosity=2"
ARG GUIX_SVCNAME="guix-daemon"

ARG GPG_KEYSERVER="pool.sks-keyservers.net"
ARG GPG_OPTS="--no-greeting"

ARG WGET_OPTS="--no-verbose --show-progress --progress=bar:force"

ARG ENTRY_D=/root
ARG PREFIX_D=/usr/local
ARG PROFILE_D=/etc/profile.d
ARG INIT_D=/etc/init.d
ARG WORK_D=/tmp

#added to resolve guix substitute problem on nss-certs 
ARG LC_ALL=en_US.utf8

# Set USER environment variable so Guix can properly set the path to the user's
# profile.
# See: https://issues.guix.info/issue/39195
ENV USER="root"

# Copy channels.scm for Guix pull
COPY scripts/channels-a20210219.scm "${GUIX_CONFIG}/channels.scm"


# Guix Packages Upgrade
# """"""""""""""""

RUN echo $LC_ALL \
    && source "${GUIX_PROFILE}/etc/profile" \
    && sh -c "'${GUIX_PROFILE}/bin/guix-daemon' --build-users-group='${GUIX_BUILD_GRP}' --disable-chroot &" \
    #&& "${GUIX_PROFILE}/bin/guix" pull ${GUIX_OPTS} \
    #&& source "${GUIX_PROFILE}/etc/profile" \
    && hash guix \
    && export GUIX_LOCPATH="$HOME/.guix-profile/lib/locale" \
    && echo $GUIX_LOCPATH \
    && source "${GUIX_PROFILE}/etc/profile" \
    && hash guix \
    && "${GUIX_PROFILE}/bin/guix" --version \
    && "${GUIX_PROFILE}/bin/guix" build --fallback zfs@2.0.3 \
    #&& "${GUIX_PROFILE}/bin/guix" build --fallback linux@5.10.16 \
    #&& "${GUIX_PROFILE}/bin/guix" build --fallback linux-firmware@20210208 \
    && "${GUIX_PROFILE}/bin/guix" describe 


WORKDIR "${ENTRY_D}"
CMD "/sbin/init"
