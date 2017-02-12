#/usr/bin/env bash

set -e

echo $UID
echo $USER

#
# This block could be wrapped up into its on helper function or script : Begin
#

BITBUCKET_KEYFILE=~/.ssh/bitbucket_id_rsa

DEPLOY_KEYFILE=~/.ssh/deploy_id_rsa

# Set up SSH access to the deployment target.
mkdir -p ~/.ssh

echo ${BITBUCKET_PRIVATE_KEY} | base64 --decode > ${BITBUCKET_KEYFILE}
chmod 600 ${BITBUCKET_KEYFILE}
cat << EOF >> ~/.ssh/config

Host bitbucket.org
    UserKnownHostsFile=/dev/null
    StrictHostKeyChecking=no
    IdentityFile=${BITBUCKET_KEYFILE}

EOF

echo ${DEPLOY_PRIVATE_KEY} | base64 --decode > ${DEPLOY_KEYFILE}
chmod 600 ${DEPLOY_KEYFILE}

cat << EOF >> ~/.ssh/config

Host ${DEPLOY_HOST}
    UserKnownHostsFile=/dev/null
    StrictHostKeyChecking=no
    IdentityFile=${DEPLOY_KEYFILE}

EOF

chmod 700 ~/.ssh
chmod 600 ~/.ssh/config


#
# This block could be wrapped up into its on helper function or script : End
#


#
# Checkout CI tools
#

mkdir -p /opt/ci-tools
cd /opt/ci-tools && git clone git@bitbucket.org:deesongroup6346/git-relay.git
ls -lA /opt/ci-tools
ls -lA /opt/ci-tools/git-relay

#
# Testing our deployment keys work
#

mkdir -p /tmp/checkout-test && cd /tmp/checkout-test && git clone ${DEPLOY_URL} .

ls -lA /tmp/checkout-test

#
# Relay commit to deployment repo
#

/opt/ci-tools/git-relay/git-relay-push.sh

echo 'Relay complete'
