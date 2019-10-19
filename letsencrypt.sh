#!/bin/bash
#
# letsencrypt.sh 
#
# (c) Niki Kovacs 2019 <info@microlinux.fr>
#
# This script generates a multi-domain SSL/TLS certificate using Certbot and
# Let's Encrypt. 

# Edit these variables according to your local configuration.
EMAIL='contact@yourmailprovider.com'
CERTBOT='/usr/bin/certbot'
CERTGROUP='certs'
CERTGROUP_GID='240'
WEBSERVER='Apache'
WEBSERVER_DAEMON='httpd'
WEBROOT='/var/www'

# Don't touch this.
TESTING=''
CERTOPT=''

# Edit hosted domains and their corresponding directories under the web root.
DOMAIN[1]='sd-123456.dedibox.fr'
WEBDIR[1]='default'

DOMAIN[2]='somedomain.com'
WEBDIR[2]='somedomain-site'

DOMAIN[3]='www.somedomain.com'
WEBDIR[3]='somedomain-site'

DOMAIN[4]='mail.somedomain.com'
WEBDIR[4]='somedomain-mail'

DOMAIN[5]='otherdomain.net'
WEBDIR[5]='otherdomain-site'

DOMAIN[6]='www.otherdomain.net'
WEBDIR[6]='otherdomain-site'

DOMAIN[7]='mail.otherdomain.net'
WEBDIR[7]='otherdomain-mail'

# Display the usage.
usage() {
  echo "Usage: ${0} OPTION"
  echo 'Create or renew an SSL/TLS certificate.'
  echo 'Options:'
  echo '  -h, --help    Show this message.'
  echo '  -t, --test    Perform a dry run.'
  echo '  -c, --cert    Create/renew a certificate.'
}

# Make sure the script is being executed with superuser privileges.
if [[ "${UID}" -ne 0 ]]
then
  echo 'Please run with sudo or as root.' >&2
  exit 1
fi

# Check if Certbot is installed.
if [[ ! -x ${CERTBOT} ]] 
then
  echo 'Certbot is not installed on this system.' >&2
  exit 1
fi

# Check parameters.
if [[ "${#}" -ne 1 ]]
then
  usage
  exit 1
fi
OPTION="${1}"
case "${OPTION}" in
  -t|--test) 
    echo 'Performing a dry run.'
    TESTING="--dry-run"
    ;;
  -h|--help) 
    usage
    exit 0
    ;;
  -c|--cert)
    ;;
  ?*) 
    usage
    exit 1
esac

# Check all directories under web root.
for (( COUNT=1 ; COUNT<=${#WEBDIR[*]} ; COUNT++ ))
do
  if [[ ! -d "${WEBROOT}/${WEBDIR[${COUNT}]}" ]]
  then
    echo "Directory ${WEBROOT}/${WEBDIR[${COUNT}]} does not exist." >&2
    exit 1
  fi
done

# Loop through domains and build command line options for Certbot
for (( COUNT=1 ; COUNT<=${#DOMAIN[*]} ; COUNT++ ))
do
  CERTOPT="${CERTOPT} --webroot-path ${WEBROOT}/${WEBDIR[${COUNT}]}\
  -d ${DOMAIN[${COUNT}]}" 
done

# Certficate files are readable to members of this group.
if ! grep -q "^${CERTGROUP}:" /etc/group 
then
  echo -n "Adding the ${CERTGROUP} group with a GID of "
  echo "${CERTGROUP_GID} to the system."
  groupadd -g ${CERTGROUP_GID} ${CERTGROUP} &> /dev/null
  if [[ "${?}" -ne 0 ]]
  then
    echo -n "Could not create the ${CERTGROUP} group " >&2
    echo "with a GID of ${CERTGROUP_GID}." >&2
    exit 1
  fi
fi

# Stop any running web server since Certbot needs TCP port 80.
if ps ax | grep -v grep | grep ${WEBSERVER_DAEMON} &> /dev/null
then
  echo "Stopping the ${WEBSERVER} web server."
  systemctl stop ${WEBSERVER_DAEMON} &> /dev/null
  if [[ "${?}" -ne 0 ]]
  then
    echo "Could not stop the ${WEBSERVER} web server." >&2
    exit 1
  fi
fi

# Create/renew a Let's Encrypt SSL/TLS certificate.
${CERTBOT} certonly \
  --non-interactive \
  --email "${EMAIL}" \
  --preferred-challenges http \
  --standalone \
  --agree-tos \
  --renew-by-default \
  ${CERTOPT} \
  ${TESTING}

# Check if Certbot works as expected.
if [[ "${?}" -ne 0 ]]
then
  echo "SSL/TLS certificate could not be created." >&2
  exit 1
fi

# Assign certificate files to the CERTGROUP group.
chgrp -R ${CERTGROUP} /etc/letsencrypt
chmod -R g=rx /etc/letsencrypt

# Start the web server.
echo "Starting the ${WEBSERVER} web server."
systemctl start ${WEBSERVER_DAEMON} &> /dev/null
if [[ "${?}" -ne 0 ]]
then
  echo "Could not start the ${WEBSERVER} web server." >&2
  exit 1
fi

exit 0
