#/usr/bin/env bash

set -e

#
# Configure Bitbucket access key for CI tools
#
# @todo
# Once the CI tools are built into the base image this can be simplified
# to a call to configure-keys.sh
# /opt/ci-tools/pipeline-ci-tools/configure-keys.sh --key=${BITBUCKET_PRIVATE_KEY} --key-file=${BITBUCKET_KEYFILE} --host=bitbucket.org
#

BITBUCKET_KEYFILE=~/.ssh/bitbucket_id_rsa
mkdir -p ~/.ssh

echo ${BITBUCKET_PRIVATE_KEY} | base64 --decode > ${BITBUCKET_KEYFILE}
chmod 600 ${BITBUCKET_KEYFILE}
cat << EOF >> ~/.ssh/config

Host bitbucket.org
    UserKnownHostsFile=/dev/null
    StrictHostKeyChecking=no
    IdentityFile=${BITBUCKET_KEYFILE}

EOF

chmod 700 ~/.ssh
chmod 600 ~/.ssh/config


#
# Checkout CI tools
#

mkdir -p /opt/ci-tools

cd /opt/ci-tools && git clone git@bitbucket.org:deesongroup6346/pipeline-ci-tools.git
cd /opt/ci-tools && git clone git@bitbucket.org:deesongroup6346/git-relay.git

ls -lA /opt/ci-tools
ls -lA /opt/ci-tools/pipeline-ci-tools
ls -lA /opt/ci-tools/git-relay


#
# Configiure the deployment SSH keys
#

/opt/ci-tools/pipeline-ci-tools/configure-keys.sh --key=${DEPLOY_PRIVATE_KEY} --key-file=${DEPLOY_KEYFILE} --host=${DEPLOY_HOST}


#
# Relay commit to deployment repo
#

# If there is a tag, push it up.
if [ -n "${BITBUCKET_TAG}" ]; then
    /opt/ci-tools/git-relay/git-relay-mirror-tag.sh  --tag-name=${BITBUCKET_TAG}
fi

if [ -n "${BITBUCKET_BRANCH}" ]; then
  target_branch=$(php -f /opt/ci-tools/pipeline-ci-tools/deployment-manager.php -- ${BITBUCKET_BRANCH} "${BITBUCKET_CLONE_DIR}/deployment-manager.json")
  dm_exit_status=$?

  if [ ${dm_exit_status} != 0 ]; then
    ${target_branch}
    exit 1
  fi

  /opt/ci-tools/git-relay/git-relay-mirror.sh  --dest-repo-branch=${target_branch}
fi

echo 'Relay complete'
