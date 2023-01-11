# syntax=docker/dockerfile:1.4
FROM asgard.orion-technologies.io/steamcmd:1.0 AS build
LABEL maintainer="price@orion-technologies.io"

ARG squad_js_version="3.6.1"
ENV STEAM_APP_ID=403240
ENV STEAM_BETA_APP_ID=774961
ENV WORKSHOP_ID=393380
ENV STEAM_BETA_PASSWORD=""
ENV STEAM_BETA_BRANCH=""
ENV USE_SQUAD_BETA=0
ENV MODS=""
ENV UPDATE_SQUAD=0

ENV RCON_PASSWORD=""
ENV SQUAD_SERVER_DIR="${USER_HOME}/Squad-Server"
# Space delimited list of mod numbers that are built into the image, e.g. 101 202 303
ENV GAMEPORT=7787 \
    QUERYPORT=27165 \
    RCONPORT=21114 \
    FIXEDMAXPLAYERS=98 \
    FIXEDMAXTICKRATE=40 \
    RANDOM=NONE

COPY --chown=${USER}:${USER} --chmod=0755 ./scripts/entry.bash "${USER_HOME}/entry.bash"
COPY --chown=root:root --chmod=0755 ./scripts/prepare-node14-yarn.bash /root/prepare-node14-yarn.bash

RUN <<__EOR__
apt-get update
# Requirements for node
apt-get install -y --no-install-suggests --no-install-recommends \
    lsb-release=11.1.0 \
    apt-transport-https=2.2.4 \
    gnupg=2.2.27-2+deb11u2 \
    sqlite=3.34.1-3

/bin/bash /root/prepare-node14-yarn.bash

apt-get remove --purge --auto-remove -y
rm -rf /var/lib/apt/lists/* /root/prepare-node14-yarn.bash

(
    mkdir -p "${SQUAD_SERVER_DIR}"
    cd "${SQUAD_SERVER_DIR}" || exit 1
    curl -L0 https://github.com/Team-Silver-Sphere/SquadJS/refs/tags/v${squad_js_version}.tar.gz --output squad-js-${squad_js_version}.tar.gz
    tar -xf squad-js-${squad_js_version}.tar.gz
    mv SquadJS-${squad_js_version} SquadJS
)

__EOR__

FROM build AS prod
SHELL [ "/bin/bash" ]
WORKDIR "${USER_HOME}"

EXPOSE 7787/udp \
            27165/tcp \
            27165/udp \
            21114/tcp \
            21114/udp

ENTRYPOINT [ "/bin/bash", "entry.bash" ]
