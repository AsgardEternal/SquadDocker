#!/bin/bash

# If we want to persist the containter and we don't want to update then we can save a whole lot of time if we mount this
# on a volume

main() {
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
