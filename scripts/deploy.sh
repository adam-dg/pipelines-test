#!/usr/bin/env bash

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

#ls -lA /opt/ci-tools
#ls -lA /opt/ci-tools/pipeline-ci-tools
#ls -lA /opt/ci-tools/git-relay


#
# Configiure the deployment SSH keys
#

/opt/ci-tools/pipeline-ci-tools/configure-keys.sh --key=${DEPLOY_PRIVATE_KEY} --key-file=${DEPLOY_KEYFILE} --host=${DEPLOY_HOST}


#
# Relay commit to deployment repo
#

deploy_url=""
if [ "${GIT_RELAY_DEST_REPO_URL}" != "" ]; then
  deploy_url="${GIT_RELAY_DEST_REPO_URL}"
elif [ "${DEPLOY_URL}" != "" ]; then
  deploy_url="${DEPLOY_URL}"
fi

src_repo_path=""
if [ "${GIT_RELAY_SRC_REPO_PATH}" != "" ]; then
  src_repo_path="${GIT_RELAY_SRC_REPO_PATH}"
elif [ "${BITBUCKET_CLONE_DIR}" != "" ]; then
  src_repo_path="${BITBUCKET_CLONE_DIR}"
fi

relay_type="snapshot"
if [ "${GIT_RELAY_TYPE}" != "" ]; then
  relay_type="${GIT_RELAY_TYPE}"
fi

# If there is a tag, push it up.
if [ -n "${BITBUCKET_TAG}" ]; then
  if [ "{$relay_type}" = "mirror" ]; then
    /opt/ci-tools/git-relay/git-relay.sh mirror tag -- --src-repo-path="${src_repo_path}" --dest-repo-url="${deploy_url}" --tag-name=${BITBUCKET_TAG}
  else
    echo "Relay type '${relay_type}' not recognised"
    exit 1
  fi
fi

if [ -n "${BITBUCKET_BRANCH}" ]; then
  set +e
  target_branch=$(php -f /opt/ci-tools/pipeline-ci-tools/deployment-manager.php -- ${BITBUCKET_BRANCH} "${BITBUCKET_CLONE_DIR}/deployment-manager.json")
  dm_exit_status=$?

  if [ ${dm_exit_status} != 0 ]; then
    ${target_branch}
    exit 1
  fi

  set -e
  if [ "{$relay_type}" = "mirror" ]; then
    /opt/ci-tools/git-relay/git-relay.sh mirror -- --src-repo-path="${src_repo_path}" --dest-repo-url="${deploy_url}" --dest-repo-branch=${target_branch}
  else
    echo "Relay type '${relay_type}' not recognised"
    exit 1
  fi
fi

echo 'Relay complete'
