# syntax=docker/dockerfile:1.4

# hadolint global ignore=DL3003,DL3008

FROM asgard-eternal.com/steamcmd:latest AS build
LABEL maintainer="price@price-hiller.com"

ARG steam_app_id=403240
ARG steam_beta_app_id=774961
ARG steam_beta_password=""
ARG steam_beta_branch=""
ARG use_squad_beta=0

ENV RCON_PASSWORD=""
ENV SQUAD_SERVER_DIR="${STEAM_HOME}/Squad-Server"
ENV GAMEPORT=7787 \
    QUERYPORT=27165 \
    RCONPORT=21114 \
    FIXEDMAXPLAYERS=98 \
    BEACONPORT=15000 \
    FIXEDMAXTICKRATE=45 \
    RANDOM=NONE


RUN <<__EOR__
apt-get update

apt-get install -y --no-install-suggests --no-install-recommends \
    lsb-release=12.0-1 \
    apt-transport-https=2.6.1 \
    gnupg=2.2.40-1.1

rm -rf /var/lib/apt/lists/*
__EOR__

FROM build AS prod
WORKDIR "${STEAM_HOME}"
COPY --chown=${STEAM_USER}:${STEAM_USER} --chmod=0744 ./scripts/entry.bash "${STEAM_HOME}/entry.bash"

EXPOSE \
    7787/udp \
    7787/tcp \
    7788/udp \
    7788/tcp \
    27165/tcp \
    27165/udp \
    21114/tcp \
    21114/udp \
    15000/udp

ARG mods=""
ENV SQUAD_MODS=${mods}
# HACK: This shouldn't be done either! The entry.bash requires the root user though for certain tasks :(
USER root
ENTRYPOINT [ "/bin/bash", "entry.bash" ]
