#!/bin/bash -e

if [[ -f ".circleci/debuglog" ]]; then
	set -x
fi

if [[ -x "tools/build.sh" ]]; then
	tools/build.sh
	exit $?
fi

go mod init
go mod download github.com/DriveClutch/clutch-common-go
go mod tidy

for dockerfile in $(find . -name Dockerfile -not -path "./vendor/*" )
do
	pkgdir=$(dirname $dockerfile)
	execname="$pkgdir/$(basename $pkgdir)"
	if [[ $pkgdir == "." ]]; then
		execname=$(basename $(pwd))
	fi

	# Make sure there is some Go files to build in this dir
	# Go build will download dependencies if there is a go.mod file in the repo being built.
	if compgen -G "$pkgdir/*.go" > /dev/null; then
		CGO_ENABLED=0 go build \
			-a \
			-installsuffix cgo \
			-ldflags "-s -X main.buildinfobuildtime=$(date '+%Y-%m-%d_%I:%M:%S%p') -X main.buildinfogithash=${CIRCLE_SHA1} -X main.buildinfoversion=${CIRCLE_TAG-latest}" \
			-o $execname \
			$pkgdir
	fi
done