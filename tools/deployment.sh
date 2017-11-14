#!/bin/bash -e

if [[ -f ".circleci/debuglog" ]]; then
	set -x
fi

# Check if there is a deployment.sh in the repo and exec
if [[ -x "tools/deployment.sh" ]]; then
	tools/deployment.sh
	exit $?
fi

# Container Images
/tools/docker.sh

# Helm Packages
/tools/helm.sh
