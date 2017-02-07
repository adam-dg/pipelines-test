#/usr/bin/env bash

set -e

#
# This block could be wrapped up into its on helper function or script : Begin
#

KEYFILE=~/.ssh/deploy_id_rsa

# Set up SSH access to the deployment target.
mkdir -p ~/.ssh

echo ${DEPLOY_PRIVATE_KEY} | base64 --decode > ${KEYFILE}
chmod 600 ${KEYFILE}

cat << EOF >> ~/.ssh/config
Host ${DEPLOY_HOST}
    UserKnownHostsFile=/dev/null
    StrictHostKeyChecking=no
    IdentityFile=${KEYFILE}
EOF
chmod 700 ~/.ssh
chmod 600 ~/.ssh/config

#
# This block could be wrapped up into its on helper function or script : End
#

mkdir -p /tmp/checkout-test && cd /tmp/checkout-test && git clone ${DEPLOY_URL} .

ls -lA /tmp/checkout-test
