#!/bin/bash -e

if [[ -f ".circleci/debuglog" ]]; then
        set -x
fi

if [[ -x "tools/helm-install.sh" ]]; then
        tools/helm-install.sh
        exit $?
fi

kubeinit() {
	echo $CL_HELM_CI_CA_CRT | base64 --decode > /tmp/ca.crt
	kubectl config set-cluster $CL_HELM_CI_CLUSTER_NAME \
		--embed-certs=true \
		--server=$CL_HELM_CI_ENDPOINT \
		--certificate-authority=/tmp/ca.crt
	rm /tmp/ca.crt
	kubectl config set-credentials circleci-$CL_HELM_CI_CLUSTER_NAME --token=$CL_HELM_CI_USER_TOKEN
	kubectl config set-context circleci-$CL_HELM_CI_CLUSTER_NAME \
		--cluster=$CL_HELM_CI_CLUSTER_NAME \
		--user=circleci-$CL_HELM_CI_CLUSTER_NAME
	kubectl config use-context circleci-$CL_HELM_CI_CLUSTER_NAME
}

helminstall() {
	l_reponame=$1
	l_appname=$2
	l_cibranch=$3
	l_namespace=$4
	l_valuesfile=$5

	setvars="--set global.runHA=false"

	if [ "$l_cibranch" != "master"  ]; then
		setvars="$setvars,imageBranch=$l_cibranch"
	fi

	if [ ! -z "$l_valuesfile" ]; then
		l_valuesfile="-f $l_valuesfile"
	fi

	helm upgrade --install $l_appname ${l_reponame}-${l_cibranch}/$l_appname --namespace $l_namespace $setvars $l_valuesfile
}

if [ -f ".circleci/nocideploy" ]; then
	echo ".circleci/nocideploy is present, skipping CI deployment!"
	exit 0
fi

# Make sure the Helm dir exists
if [ ! -d ".helm" ]; then
	echo "No Helm projects found."
	exit 0
fi

# Setup the kubernetes namespace
CINAMESPACE=""
if [ -f ".circleci/namespace" ]; then
	CINAMESPACE=$(cat .circleci/namespace | tr -d '\n')
fi

# Check if this is a CI deployment branch
CIBRANCH="master"
if [ -f ".circleci/cibranch" ]; then
	# cibranch file exists, use this value
	CIBRANCH=$(cat .circleci/cibranch | tr -d '\n')
fi
if [ "$CIBRANCH" != "$CIRCLE_BRANCH" ]; then
	echo "$CIBRANCH != $CIRCLE_BRANCH, NOT deploying this build to CI!"
	exit 0
fi

echo "Initializing kubectl for CI Kubernetes Cluster"
kubeinit

echo "Setting GOOGLE_APPLICATION_CREDENTIALS"
if [ ! -f "${HOME}/gcp-key.json" ]; then
	echo "Could not find the GCP key at ${HOME}/gcp-key.json!  This should exist from the helm.sh step."
	exit 1
fi
export GOOGLE_APPLICATION_CREDENTIALS=${HOME}/gcp-key.json
helm repo update

for appdir in .helm/*
do
	if [ -d "$appdir" ]; then
		appname=$(basename $appdir)
		valuesfile=""
		if [ -f "$appdir/values-ci.yaml" ]; then
			valuesfile="$appdir/values-ci.yaml"
		fi
		if [ "$CINAMESPACE" == "" ]; then
			echo "The Kubernetes namespace has not been set in .circleci/namespace!"
			exit 1
		fi
		helminstall $CIRCLE_PROJECT_REPONAME $appname $CIBRANCH $CINAMESPACE $valuesfile
	fi
done

