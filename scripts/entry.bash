#!/bin/bash

set -ueEo pipefail

STEAM_APP_ID=403240
WORKSHOP_ID=393380

install-squad-server() {
	su "${STEAM_USER}" - <<-__EOC__
		mkdir -p "${SQUAD_SERVER_DIR}"
			    "${STEAM_CMD_INSTALL_DIR}/steamcmd.sh" \
			        +force_install_dir "${SQUAD_SERVER_DIR}" \
			        +login anonymous \
			        +app_update ${STEAM_APP_ID} validate \
			        +quit
	__EOC__
}

install-squad-mod() {
	local mod="${1}"
	su "${STEAM_USER}" - <<-__EOC__
		printf "\n\n######\nAdding mod: %s\n######\n\n" "${mod}"
		counter=0
		until "${STEAM_CMD_INSTALL_DIR}/steamcmd.sh" \
		    +force_install_dir "${SQUAD_SERVER_DIR}/SquadGame/Plugins/Mods/${mod}" \
		    +login anonymous \
		    +workshop_download_item "${WORKSHOP_ID}" "${mod}" validate \
		    +quit; do
		    printf "\nDid Not Fully Download %s, making another attempt.\n" "${mod}"
		    (( counter++ ))
		    if (( counter > 5 )); then
		        printf "Critical failure, could not download the mod: %s\n" "${mod}"
		        exit 1
		    fi
		done
	__EOC__

}

init-docker-mount() {
	chown -R "${STEAM_USER}:${STEAM_USER}" "${SQUAD_SERVER_DIR}"
}

update-rcon-config() {
	# Update RCON configuration based on the fed in environment value
	while read -r line; do
		if [[ "${line}" == Password=* ]]; then
			# Overwrites the password
			echo "${line//Password=*/Password="${RCON_PASSWORD}"}"
		elif [[ "${line}" == Port=* ]]; then
			# Overwrites the rcon port
			echo "${line//Port=*/Port="${RCONPORT}"}"
		else
			echo "${line}"
		fi
	done <"${SQUAD_SERVER_DIR}/SquadGame/ServerConfig/Rcon.cfg" >"rcon.temp" && mv "rcon.temp" "${SQUAD_SERVER_DIR}/SquadGame/ServerConfig/Rcon.cfg"

}

start-squad-server() {
	su "${STEAM_USER}" - <<-__EOC__
		printf "Starting the Squad Server....\n"
		"${SQUAD_SERVER_DIR}/SquadGameServer.sh" \
			Port="${GAMEPORT}" \
			QueryPort="${QUERYPORT}" \
			FIXEDMAXTICKRATE="${FIXEDMAXTICKRATE}" \
			FIXEDMAXPLAYERS="${FIXEDMAXPLAYERS}" \
		      beaconport="${BEACONPORT}" &
		printf "Squad Server Started!\n"

		wait
	__EOC__

}

main() {
	printf "Got squad server dir as: '%s'\n" "${SQUAD_SERVER_DIR}"
	init-docker-mount
	install-squad-server

	IFS="," read -ra squad_mods <<<"${SQUAD_MODS:-}"
	printf "Got squad mods list as: %s\n" "${squad_mods[*]}"
	for mod in "${squad_mods[@]}"; do
		install-squad-mod "${mod}"
	done

	update-rcon-config

	start-squad-server

}

main
