#!/bin/bash

# If we want to persist the containter and we don't want to update then we can save a whole lot of time if we mount this
# on a volume

main() {
	chown -R "${USER}:${USER}" "${USER_HOME}" || exit 1

	if [[ -d "${USER_HOME}/ServerConfig" ]]; then
		chown -R "${USER}:${USER}" "${USER_HOME}/ServerConfig"
	fi

	local steam_cmd_base_str="${STEAM_CMD_INSTALL_DIR}/steamcmd.sh +force_install_dir ${SQUAD_SERVER_DIR} +login anonymous"
	local steam_cmd_str="${steam_cmd_base_str} +app_update ${STEAM_APP_ID}"
	if (( USE_SQUAD_BETA == 1 )); then
		steam_cmd_str="${steam_cmd_str} -beta ${STEAM_BETA_BRANCH} -betapassword ${STEAM_BETA_PASSWORD}"
	fi
	steam_cmd_str="${steam_cmd_str} validate +quit"
	printf "\e[35m> Issuing SteamCMD Command:\e[0m %s\n" "${steam_cmd_str}"
	eval "${steam_cmd_str}"


	# Remove existing non-default symlinks in mod dir
	for mod in "${SQUAD_SERVER_DIR}/SquadGame/Plugins/Mods"/[0-9]*; do
		rm "${mod}"
	done

	printf "\e[96m> Provided mods list:\e[0m %s\n" "${MODS}"
	# shellcheck disable=2153
	IFS="," read -ra squad_mods <<< "${MODS}"
	for mod in "${squad_mods[@]}"; do
		steam_cmd_str="${steam_cmd_base_str}"
		steam_cmd_str="${steam_cmd_str} +workshop_download_item ${WORKSHOP_ID} ${mod} validate +quit"
		printf "\e[92m> Adding mod:\e[0m %s\n" "${mod}"
		printf "\e[35m> Issuing SteamCMD Command:\e[0m %s\n" "${steam_cmd_str}"
		local counter=0
		until eval "${steam_cmd_str}"; do
			printf "\nDid Not Fully Download %s, making another attempt.\n" "${mod}"
			(( counter++ ))
			if (( counter > 5 )); then
				printf "Critical failure, could not download the mod: %s\n" "${mod}"
				exit 1
			fi
		done
		ln -s "${SQUAD_SERVER_DIR}/steamapps/workshop/content/${WORKSHOP_ID}/${mod}" "${SQUAD_SERVER_DIR}/SquadGame/Plugins/Mods/${mod}"
	done

	local mounted_files
	mounted_files="$(shopt -s nullglob dotglob; echo "${USER_HOME}/ServerConfig/")"
	if (( ${#mounted_files} )); then
		rsync -r "${USER_HOME}/ServerConfig/" "${SQUAD_SERVER_DIR}/SquadGame/ServerConfig/"
	fi


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
	done < "${SQUAD_SERVER_DIR}/SquadGame/ServerConfig/Rcon.cfg" > "rcon.temp" && mv "rcon.temp" "${SQUAD_SERVER_DIR}/SquadGame/ServerConfig/Rcon.cfg"


	chown -R "${USER}:${USER}" "${USER_HOME}"
	su "${USER}" - "${SQUAD_SERVER_DIR}/SquadGameServer.sh" \
		Port="${GAMEPORT}" \
		QueryPort="${QUERYPORT}" \
		FIXEDMAXTICKRATE="${FIXEDMAXTICKRATE}" \
		FIXEDMAXPLAYERS="${FIXEDMAXPLAYERS}"
}

main
