#!/bin/bash

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

"${SQUAD_SERVER_DIR}/SquadGameServer.sh" \
	Port="${GAMEPORT}" \
	QueryPort="${QUERYPORT}" \
	FIXEDMAXTICKRATE="${FIXEDMAXTICKRATE}" \
	FIXEDMAXPLAYERS="${FIXEDMAXPLAYERS}"
