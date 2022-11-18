DODocker
--------

A hacked-together replacement for docker-machine for DigitalOcean.

Add the following to your ssh config:

```
Include ~/.dodocker/hosts/*/ssh-config
```

Create a token json at ~/.dodocker/tokens.json:

```
{
"account_name": "API token"
}
```

Run the `dodocker.sh` script as:

```
dodocker.sh token_name machine_name
```

where `token_name` is one of the account names in the `tokens.json` file and `machine_name` is what you'd like the droplet to be named. Afterward, you can use Docker directly by doing:

```
export DOCKER_HOST=ssh://dodocker-$machine_name
```

or SSH to the host with:

```
ssh dodocker-$machine_name
```
