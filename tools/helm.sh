#!/bin/bash -e

if [[ -f ".circleci/debuglog" ]]; then
	set -x
fi

if [[ ! -d ".helm" ]]; then
	echo "Helm directory does not exist, skipping packaging"
	exit 0
fi

helm repo add mproduction $S3_HELM_BUCKET

cd .helm

GITHASHLONG=$(git rev-parse HEAD)
GITHASHSHORT=$(git rev-parse --short HEAD)
DT=$(date "+%Y.%m%d.%H%M")
PKGVER="${DT}-${GITHASHSHORT}"

for chartpath in */Chart.yaml
do
	reponame=$(basename $(dirname $chartpath))
	grep -Ev "^version:|^appVersion:" ${chartpath} > ${chartpath}.new
	echo "appVersion: ${GITHASHLONG}" >> ${chartpath}.new
	echo "version: ${PKGVER}" >> ${chartpath}.new
	mv ${chartpath}.new ${chartpath}

	helm package $reponame
	helm s3 push ./telematics-calamp-trip-${PKGVER}.tgz mproduction
done
