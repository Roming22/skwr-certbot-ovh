#!/bin/bash
SCRIPT_DIR="$(dirname "$(realpath "$0")")"

DEFAULT="${SCRIPT_DIR}/k8s/config.default.env"
SECRET="${SCRIPT_DIR}/k8s/config.secret.env"
for CONFIG in "${DEFAULT}" "${SECRET}"; do
	[[ -e "${CONFIG}" ]] && source "${CONFIG}"
done
unset CONFIG

ask(){
	local TYPE="$1"
	local MODE="$2"
	local VAR="$3"
	local PROMPT="$4"

	local DEFAULT
	local PAD
	local INPUT
	local READ_ARGS

	[[ -n "${!VAR}" ]] && DEFAULT="${!VAR}" || unset DEFAULT

	case "$TYPE" in
		value)
			PROMPT="${PROMPT}$([[ -n "${DEFAULT}" ]] && echo -e " [${DEFAULT}]")"
			;;
		secret)
			READ_ARGS="-s"
			PROMPT="${PROMPT}$([[ -n "${DEFAULT}" ]] && echo -e " [press enter to use existing value]")"
			;;
		*)
			echo "Unsupported type: $TYPE" >&2
			exit 1
			;;
	esac
	case "$MODE" in
		mandatory) ;;
		optional)
			PAD="-"
			;;
		*)
			echo "Unsupported mode: $MODE" >&2
			exit 1
			;;
	esac

	read ${READ_ARGS} -p "${PROMPT}: " INPUT

	case "$TYPE" in
		secret)
			echo
			INPUT="$( echo -n "${INPUT}" | base64  | tr -d '\n' )"
			;;
	esac
	export $VAR="${INPUT:-$DEFAULT}"
	[[ -z "${!VAR}${PAD}" ]] && echo "Invalid value: Do not leave blank" && exit 1
	VAR_LIST="${VAR_LIST} ${VAR}"
}

write_secret(){
    VAR_LIST=( $VAR_LIST )
    for VAR in ${VAR_LIST[@]}; do
        echo "$VAR=${!VAR}"
    done > $SECRET
}

create_secret(){
	ask value mandatory EMAIL "Email for letsencrypt registration"
	ask value mandatory DOMAIN "Domain for which the wildcard certificate is generated"
	ask value mandatory OVH_ENDPOINT "OVH Endpoint (ovh-ca, ovh-eu)"
	ask secret mandatory OVH_APPLICATION_KEY "OVH application key"
	ask secret mandatory OVH_APPLICATION_SECRET "OVH application secret"
	ask secret mandatory OVH_CONSUMER_KEY "OVH consumer key"
	write_secret

	export CREDENTIALS_INI=$(echo "
		# OVH API credentials used by Certbot
		dns_ovh_endpoint = $OVH_ENDPOINT
		dns_ovh_application_key = $(echo $OVH_APPLICATION_KEY | base64 --decode)
		dns_ovh_application_secret = $(echo $OVH_APPLICATION_SECRET | base64 --decode)
		dns_ovh_consumer_key = $(echo $OVH_CONSUMER_KEY | base64 --decode)" \
	| grep -Ev "^\s*$" | sed 's:^\s*::' | base64 -w 0)
}

process_templates(){
	for TEMPLATE in $(find "${SCRIPT_DIR}/k8s" -name \*.in.\*); do
		TARGET="$(echo "${TEMPLATE}" | sed "s:\.in\.:.secret.:")"
		envsubst < $TEMPLATE > $TARGET
	done
}

create_secret
process_templates
