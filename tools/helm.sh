#!/bin/bash -e

if [[ -f ".circleci/debuglog" ]]; then
	set -x
fi

if [[ ! -d ".helm" ]]; then
	echo "Helm directory does not exist, skipping packaging"
	exit 0
fi

echo $GCP_AUTH_KEY | base64 -d - > ${HOME}/gcp-key.json
export GOOGLE_APPLICATION_CREDENTIALS=${HOME}/gcp-key.json

helm repo add $HELM_REPO_NAME $HELM_GS_BUCKET

cd .helm

GITHASHLONG=$(git rev-parse HEAD)
GITHASHSHORT=$(git rev-parse --short HEAD)
DT=$(date "+%Y%m%d.%H%M.%S")
PKGVER="${DT}"

for chartpath in */Chart.yaml
do
	reponame=$(basename $(dirname $chartpath))
	grep -Ev "^version:|^appVersion:" ${chartpath} > ${chartpath}.new
	echo "appVersion: ${GITHASHLONG}" >> ${chartpath}.new
	echo "version: ${PKGVER}" >> ${chartpath}.new
	mv ${chartpath}.new ${chartpath}

	helm package $reponame
	helm gcs push ./${reponame}-${PKGVER}.tgz $HELM_REPO_NAME
done
