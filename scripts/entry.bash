#!/bin/bash

# If we want to persist the container and we don't want to update then we can save a whole lot of time if we mount this
# on a volume

main() {
	local mount="/docker-mount/"
	chown -R "${USER}:${USER}" "${mount}"
	if [[ -r "${mount}/ServerConfig" ]]; then
		printf "Linking ServerConfig from '%s' -> '%s'\n" "${mount}/ServerConfig/" "${SQUAD_SERVER_DIR}/SquadGame/ServerConfig/"
		for file in "${mount}/ServerConfig/"*; do
			ln -sf "${file}" "${SQUAD_SERVER_DIR}/SquadGame/ServerConfig/$(basename "${file}")"
		done
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

	chown -R "${USER}:${USER}" "${SQUAD_SERVER_DIR}/SquadGame/"

	su "${USER}" - <<- __EOC__
		printf "Starting the Squad Server....\n"
		"${SQUAD_SERVER_DIR}/SquadGameServer.sh" \
			Port="${GAMEPORT}" \
			QueryPort="${QUERYPORT}" \
			FIXEDMAXTICKRATE="${FIXEDMAXTICKRATE}" \
			FIXEDMAXPLAYERS="${FIXEDMAXPLAYERS}" >/dev/null 2>&1 &
		printf "Squad Server Started!\n"

		wait
	__EOC__

}

main
