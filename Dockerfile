# syntax=docker/dockerfile:1.4
FROM asgard.orion-technologies.io/steamcmd:1.0 AS build

LABEL maintainer="price@orion-technologies.io"

ARG steam_app_id=403240
ARG steam_beta_app_id=774961
ARG workshop_id=393380
ARG steam_beta_password=""
ARG steam_beta_branch=""
ARG use_squad_beta=0
ARG squad_mods="()"

ENV RCON_PASSWORD=""
ENV SQUAD_SERVER_DIR="${USER_HOME}/Squad-Server"
# Space delimited list of mod numbers that are built into the image, e.g. 101 202 303
ENV GAMEPORT=7787 \
    QUERYPORT=27165 \
    RCONPORT=21114 \
    FIXEDMAXPLAYERS=98 \
    FIXEDMAXTICKRATE=40 \
    RANDOM=NONE

SHELL [ "/bin/bash", "-c" ]

RUN <<__EOR__

if (( use_squad_beta == 1 )); then
    # Install Squad from the Beta branch
    "${STEAM_CMD_INSTALL_DIR}/steamcmd.sh" \
        +force_install_dir "${SQUAD_SERVER_DIR}" \
        +login anonymous \
        +app_update ${steam_app_id} validate \
        -beta "${steam_beta_branch}" \
        -betapassword "${steam_beta_password}" \
        +quit
else
    # Install Squad from the release version
    "${STEAM_CMD_INSTALL_DIR}/steamcmd.sh" \
        +force_install_dir "${SQUAD_SERVER_DIR}" \
        +login anonymous \
        +app_update ${steam_app_id} validate \
        +quit
fi

# Install mods as part of image

declare -A squad_mods="${squad_mods}"
for mod in "${squad_mods[@]}"; do
    "${STEAM_CMD_INSTALL_DIR}/steamcmd.sh" \
        +force_install_dir "${SQUAD_SERVER_DIR}" \
        +login anonymous \
        +workshop_download_item "${workshop_id}" "${mod}" \
        +quit

    mv "${SQUAD_SERVER_DIR}/steamapps/workshop/content/${workshop_id}/${mod}" \
        "${SQUAD_SERVER_DIR}/SquadGame/Plugins/Mods/${mod}"
done


__EOR__

EXPOSE ${GAMEPORT}/udp \
            ${QUERYPORT}/tcp \
            ${QUERYPORT}/udp \
            ${RCONPORT}/tcp \
            ${RCONPORT}/udp

COPY ./scripts/entry.sh "/entry.sh"

ENTRYPOINT [ "/bin/bash", "/entry.sh" ]
