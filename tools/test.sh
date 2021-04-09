#!/bin/bash -e

if [[ -f ".circleci/debuglog" ]]; then
	set -x
fi

# Check if there is a test.sh in the repo and exec
if [[ -x "tools/test.sh" ]]; then
	tools/test.sh
	exit $?
fi

mkdir -p _tmp/artifacts

go test -v -covermode=count -coverprofile=_tmp/artifacts/coverage.out

go tool cover -html=_tmp/artifacts/coverage.out -o _tmp/artifacts/coverage.html