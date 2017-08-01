#!/bin/bash -e

if [[ -f ".circleci/debuglog" ]]; then
	set -x
fi

# Check if there is a test.sh in the repo and exec
if [[ -x "tools/test.sh" ]]; then
	tools/test.sh
	exit $?
fi

# NOTE the $(glide novendor) is to exclude vendor packages testing
go test $(glide novendor)
