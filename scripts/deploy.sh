#/usr/bin/env bash

set -e

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

mkdir -p /tmp/checkout-test && cd /tmp/checkout-test && git clone ${DEPLOY_URL} .

ls -lA /tmp/checkout-test
