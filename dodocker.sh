#!/bin/bash

if [[ $# -ne 2 ]]
then
	echo "Usage: $0 token_name machine_name"
	exit
fi

token_name="$1"
name="$2"
DO_TOKEN="$(jq -r ."$token_name" "$HOME"/.dodocker/tokens.json)"
CONF_DIR="$HOME"/.dodocker/hosts/"$name"

if [[ -e "$CONF_DIR" ]]
then
	echo "Error: host named $name already exists"
	exit
fi

mkdir "$CONF_DIR"

ssh-keygen -b 2048 -t rsa -f "$CONF_DIR"/id_rsa -q -N ""
curl -s -X POST -H 'Content-Type: application/json' -H "Authorization: Bearer $DO_TOKEN" -d '{"name":"'"$name"'","public_key":"'"$(cat "$CONF_DIR"/id_rsa.pub)"'"}' https://api.digitalocean.com/v2/account/keys >/dev/null

SSH_FINGERPRINT="$(ssh-keygen -l -E md5 -f "$CONF_DIR"/id_rsa.pub | awk '{print $2}' | sed 's#MD5:##')"

curl -s -X POST -H 'Content-Type: application/json' -H "Authorization: Bearer $DO_TOKEN" -d '{"name":"'"$name"'","region":"sfo2","size":"s-1vcpu-1gb","image":"docker-20-04","monitoring":true,"ssh_keys":["'"$SSH_FINGERPRINT"'"]}' https://api.digitalocean.com/v2/droplets > "$CONF_DIR"/droplet.json
DROPLET_ID="$(jq -r .droplet.id "$CONF_DIR"/droplet.json)"

echo -n Waiting for an IP
while :
do
	echo -n .
	curl -s -H 'Content-Type: application/json' -H "Authorization: Bearer $DO_TOKEN" https://api.digitalocean.com/v2/droplets/$DROPLET_ID > "$CONF_DIR"/droplet.json.tmp
	IP="$(jq -r '.droplet.networks.v4[] | select(.type=="public") | .ip_address' "$CONF_DIR"/droplet.json.tmp)"

	if [[ ! -z "$IP" ]]
	then
		echo " $IP"
		mv "$CONF_DIR"/droplet.json.tmp "$CONF_DIR"/droplet.json
		break
	fi

	sleep 1
done


cat <<EOF > "$CONF_DIR"/ssh-config
Host dodocker-$name
	Hostname $IP
	IdentityFile $CONF_DIR/id_rsa
	User root
EOF


echo
echo "To use:"
echo "export DOCKER_HOST=ssh://dodocker-$name"
echo
echo "To SSH:"
echo "ssh dodocker-$name"
