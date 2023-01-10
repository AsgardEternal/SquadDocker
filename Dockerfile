# syntax=docker/dockerfile:1.4
FROM asgard.orion-technologies.io/steamcmd:1.0 AS build
LABEL maintainer="price@orion-technologies.io"

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

COPY --chown=${USER} ./scripts/entry.bash "${USER_HOME}/entry.bash"

FROM build AS prod
SHELL [ "/bin/bash" ]
WORKDIR "${USER_HOME}"

EXPOSE 7787/udp \
            27165/tcp \
            27165/udp \
            21114/tcp \
            21114/udp

ENTRYPOINT [ "/bin/bash", "entry.bash" ]
