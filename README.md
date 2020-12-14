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
