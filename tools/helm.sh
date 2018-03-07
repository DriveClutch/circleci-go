#!/bin/bash -e

if [[ -f ".circleci/debuglog" ]]; then
	set -x
fi

# If this repo doesn't contain a .helm directory, then no need to continue
if [[ ! -d ".helm" ]]; then
	echo "Helm directory does not exist, skipping packaging"
	exit 0
fi


# Figure out where we are and if we should be interacting with HELMREPO
 DOREMOTE=false
if [[ ! -z $CIRCLE_BUILD_NUM && ( $CIRCLE_BRANCH == "develop" || $CIRCLE_BRANCH == "master" || $CIRCLE_BRANCH =~ "hotfix"* || $CIRCLE_BRANCH =~ "release"* ) ]]; then
    DOREMOTE=true
else
    echo "*NOT* interacting with HELMREPO, either because branchname is not appropriate or not actually in a circleci environment"
fi

# Set the GCP auth key using data provided by the CircleCI context
echo $GCP_AUTH_KEY | base64 -d - > ${HOME}/gcp-key.json
export GOOGLE_APPLICATION_CREDENTIALS=${HOME}/gcp-key.json

REPONAME="${CIRCLE_PROJECT_REPONAME}-${CIRCLE_BRANCH}"
REPOLOCATION="${HELM_GS_BUCKET}/${REPONAME}"

echo "Check if the repo is initialized"
set +e # Turn off failure dumping

helm repo add $REPONAME $REPOLOCATION
RET=$?
if [ "$RET" != "0" ]; then
	echo "$REPONAME was not initialized at $REPOLOCATION, performing bucket initialization"
	helm gcs init $REPOLOCATION
fi

set -e # Turn on failure dumping

echo "Adding $REPONAME repo to helm"
helm repo add $REPONAME $REPOLOCATION

cd .helm

GITHASHLONG=$(git rev-parse HEAD)
GITHASHSHORT=$(git rev-parse --short HEAD)
DT=$(date "+%Y%m%d.%H%M.%S")
PKGVER="${DT}"

# Run linter first on all packages
for chartpath in */Chart.yaml
do
	pkgname=$(basename $(dirname $chartpath))
	helm lint $pkgname
done

for chartpath in */Chart.yaml
do
	pkgname=$(basename $(dirname $chartpath))

	helm package --version=$PKGVER --app-version=$GITHASHLONG $pkgname
    if $DOREMOTE; then
	    helm gcs push ./${pkgname}-${PKGVER}.tgz $REPONAME
    fi
done
