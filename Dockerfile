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

FROM alpine:3.12.3 AS build

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


# System
# ^^^^^^

# Set USER environment variable so Guix can properly set the path to the user's
# profile.
#
# See: https://issues.guix.info/issue/39195
ENV USER="root"

RUN apk add --no-cache ca-certificates gnupg openrc wget                        \
    # OpenRC: Disable login consoles.
    && sed -i '/^tty[0-9]\+:.*:\(re\)\?spawn:/d' /etc/inittab                   \
    # OpenRC: Define subsystem.
    && sed -i 's/^#\?rc_sys=".*"/rc_sys="docker"/' /etc/rc.conf

# git
RUN apk add --no-cache git

# build-base
# RUN apk add --no-cache build-base

# Guix
# ^^^^

# Installation
# """"""""""""

WORKDIR "${WORK_D}"
RUN wget ${WGET_OPTS} "${GUIX_URL}.sig"                                         \
    && wget ${WGET_OPTS} "${GUIX_URL}"

RUN gpg ${GPG_OPTS} --keyserver "${GPG_KEYSERVER}"                              \
                    --recv-keys "${GUIX_OPENPGP_KEY_ID}"                        \
    && gpg ${GPG_OPTS} --verify "${GUIX_ARCHIVE}.sig"                           \
    && tar -xJvf "${GUIX_ARCHIVE}" -C /                                         \
    && rm -f "${GUIX_ARCHIVE}"                                                  \
    && rm -f "${GUIX_ARCHIVE}.sig"


# Environment Setup
# """""""""""""""""

# Setup Guix profile.
RUN mkdir --parents "$(dirname "${GUIX_PROFILE}")"                              \
    && ln -s "${GUIX_SYS_PROFILE}" "${GUIX_PROFILE}"                            \
    # Enable GNU Guix substitutions.
    && sh -c "'${GUIX_PROFILE}/bin/guix' archive --authorize < '${GUIX_PROFILE}/share/guix/ci.guix.gnu.org.pub'" \
    # Make Guix command available system wide (in case profile is not loaded).
    && mkdir --parents "${PREFIX_D}/bin"                                        \
    && ln -s "${GUIX_SYS_PROFILE}/bin/guix" "${PREFIX_D}/bin/guix"

# Enable default Guix profile for login shell.
COPY scripts/guix.sh "${PROFILE_D}/guix.sh"

# Create build users.
RUN addgroup -S "${GUIX_BUILD_GRP}"                                             \
    && for i in $(seq -w 1 ${GUIX_MAX_JOBS});                                   \
       do                                                                       \
           adduser -S                                                           \
                   -g "${GUIX_BUILD_GRP}" -G "${GUIX_BUILD_GRP}"                \
                   -h /var/empty/guix -s "$(command -v nologin)"                \
                   "${GUIX_BUILD_USER}${i}";                                    \
       done

# Install init script.
COPY scripts/guix-daemon "${INIT_D}/${GUIX_SVCNAME}"
RUN chmod 0755 "${INIT_D}/${GUIX_SVCNAME}" \
    && rc-update add "${GUIX_SVCNAME}" default

# Copy channels.scm for Guix pull
COPY scripts/channels.scm "${GUIX_CONFIG}/channels.scm"


# Guix Packages Upgrade
# """"""""""""""""

RUN cat "${GUIX_CONFIG}/channels.scm"\
    && source "${GUIX_PROFILE}/etc/profile" \
    && sh -c "'${GUIX_PROFILE}/bin/guix-daemon' --build-users-group='${GUIX_BUILD_GRP}' --disable-chroot &" \
    && "${GUIX_PROFILE}/bin/guix" pull ${GUIX_OPTS} \
    && source "$GUIX_PROFILE/etc/profile" \
    && hash guix \
    && "${GUIX_PROFILE}/bin/guix" package ${GUIX_OPTS} --upgrade \
    && "${GUIX_PROFILE}/bin/guix" gc \
    && "${GUIX_PROFILE}/bin/guix" gc --optimize \
    && "${GUIX_PROFILE}/bin/guix" --version \
    && "${GUIX_PROFILE}/bin/guix" describe


# Image Finalization
# ^^^^^^^^^^^^^^^^^^
# keep wget
# RUN apk del --no-cache gnupg wget
RUN apk del --no-cache gnupg

WORKDIR "${ENTRY_D}"
CMD "/sbin/init"
