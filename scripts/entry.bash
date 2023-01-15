#!/bin/bash

# If we want to persist the container and we don't want to update then we can save a whole lot of time if we mount this
# on a volume

main() {
	local mount="/docker-mount/"
	chown -R "${USER}:${USER}" "${mount}"
	if [[ -r "${mount}/ServerConfig" ]]; then
		printf "Syncing ServerConfig from '%s' -> '%s'\n" "${mount}/ServerConfig/" "${SQUAD_SERVER_DIR}/SquadGame/ServerConfig/"
		rsync -r "${mount}/ServerConfig/" "${SQUAD_SERVER_DIR}/SquadGame/ServerConfig/"
	fi

	if [[ -r "${mount}/SquadJS.json" ]]; then
		printf "Syncing SquadJS Config from '%s' -> '%s'\n" "${mount}/SquadJS.json" "${USER_HOME}/SquadJS/config.json"
		rsync "${mount}/SquadJS.json" "${USER_HOME}/SquadJS/config.json"
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
		FIXEDMAXPLAYERS="${FIXEDMAXPLAYERS}" &

	(cd "${USER_HOME}/SquadJS" && su "${USER}" node index.js) &

	wait -n

	echo $?
}

main
