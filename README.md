# Multi-domain SSL/TLS certificates using Certbot and Let's Encrypt

(c) Niki Kovacs 2019

The Bash shell script `letsencrypt.sh` generates multi-domain SSL/TLS
certificates using Certbot and Let's Encrypt.

Before running the script, edit it to provide some basic information:

  * `EMAIL`: the server admin's email address (for expiration notifications)

  * `WEBROOT`: your web server's root directory (`/var/www`, etc.)

  * `DOMAIN[x]`: your hosted domains (`somedomain.com`, `otherdomain.net`,
     etc.)

  * `WEBDIR[x]`: the corresponding directories (`somedomain-site`,
    `otherdomain-site`, etc.)

Copy the `letsencrypt.sh` script to a sensible location like your `~/bin`
directory and make sure it's executable.

Display basic usage:

```
# ./letsencrypt.sh --help
```

Perform a dry run:

```
# ./letsencrypt.sh --test
```

Generate or renew an SSL/TLS certificate:

```
# ./letsencrypt.sh --cert
```

