# syntax=docker/dockerfile:1.4
FROM asgard.orion-technologies.io/steamcmd:1.0 AS build
LABEL maintainer="price@orion-technologies.io"

ARG steam_app_id=403240
ARG steam_beta_app_id=774961
ARG workshop_id=393380
ARG steam_beta_password=""
ARG steam_beta_branch=""
ARG use_squad_beta=0
ARG mods=""

ENV RCON_PASSWORD=""
ENV SQUAD_SERVER_DIR="${USER_HOME}/Squad-Server"
ENV GAMEPORT=7787 \
    QUERYPORT=27165 \
    RCONPORT=21114 \
    FIXEDMAXPLAYERS=98 \
    FIXEDMAXTICKRATE=40 \
    RANDOM=NONE
ENV SQUADJS_VERSION="3.6.1"

COPY --chown=${USER}:${USER} --chmod=0744 ./scripts/entry.bash "${USER_HOME}/entry.sh"
COPY --chown=root:root --chmod=0744 ./scripts/prepare-node14-yarn.bash /root/prepare-node14-yarn.bash

SHELL [ "/bin/bash", "-c" ]

# hadolint ignore=DL3003
RUN <<__EOR__

apt-get update

apt-get install -y --no-install-suggests --no-install-recommends \
    lsb-release=11.1.0 \
    apt-transport-https=2.2.4 \
    gnupg=2.2.27-2+deb11u2 \
    sqlite=3.34.1-3

/root/prepare-node14-yarn.bash

apt-get install -y --no-install-suggests --no-install-recommends \
    nodejs

apt-get install -y --no-install-suggests --no-install-recommends \
	wget \
	unzip

apt-get remove -y cmdtest

curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list

apt-get update
apt-get install -y yarn

rm -rf /var/lib/apt/lists/* /root/prepare-node14-yarn.bash

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
printf "Provided mods list: %s\n" "${mods}"
IFS="," read -ra squad_mods <<< "${mods}"
for mod in "${squad_mods[@]}"; do
    printf "\n\n######\nAdding mod: %s\n######\n\n" "${mod}"
    counter=0
    until "${STEAM_CMD_INSTALL_DIR}/steamcmd.sh" \
        +force_install_dir "${SQUAD_SERVER_DIR}/steamapps/workshop/content/${workshop_id}/${mod}" \
        +login anonymous \
        +workshop_download_item "${workshop_id}" "${mod}" \
        +quit; do
        printf "\nDid Not Fully Download %s, making another attempt.\n" "${mod}"
        (( counter++ ))
        if (( counter > 5 )); then
            printf "Critical failure, could not download the mod: %s\n" "${mod}"
            exit 1
        fi
    done


    # Link the mod instead of moving it into place, this allows steamcmd to update the mod in place if for whatever
    # reason that becomes necessary. In reality nightly builds/builds via CI should update these mods. More of a nicety
    # than something necessary.
    ln -s "${SQUAD_SERVER_DIR}/steamapps/workshop/content/${workshop_id}/${mod}" "${SQUAD_SERVER_DIR}/SquadGame/Plugins/Mods/${mod}"
    #cp -R "${SQUAD_SERVER_DIR}/steamapps/workshop/content/${workshop_id}/${mod}" "${SQUAD_SERVER_DIR}/SquadGame/Plugins?mods/${mod}"
done

#download squadjs
wget https://github.com/Team-Silver-Sphere/SquadJS/archive/refs/tags/v${SQUADJS_VERSION}.zip -O "${USER_HOME}/SquadJS.zip"
unzip "${USER_HOME}/SquadJS.zip"
mv "${USER_HOME}/SquadJS-${SQUADJS_VERSION}" "${USER_HOME}/SquadJS"
cd "${USER_HOME}/SquadJS"
yarn install

__EOR__

FROM build AS prod
WORKDIR "${USER_HOME}"

EXPOSE 3305/udp \
    3305/tcp \
    7787/udp \
    7787/tcp \
    7788/udp \
    7788/tcp \
    27165/tcp \
    27165/udp \
    21114/tcp \
    21114/udp

ENTRYPOINT [ "/bin/bash", "entry.sh" ]
