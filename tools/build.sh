#!/bin/bash -ex

for dockerfile in $(find . -name Dockerfile -not -path "./vendor/*" )
do
	pkgdir=$(dirname $dockerfile)
	CGO_ENABLED=0 go build -a -installsuffix cgo -ldflags "-s -X main.buildinfobuildtime=$(date '+%Y-%m-%d_%I:%M:%S%p') -X main.buildinfogithash=${CIRCLE_SHA1} -X main.buildinfoversion=${CIRCLE_TAG-latest}" $pkgdir
done
