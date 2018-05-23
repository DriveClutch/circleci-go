#!/bin/bash -e

if [[ -f ".circleci/debuglog" ]]; then
        set -x
fi

if [[ -x "tools/helm-install.sh" ]]; then
        tools/helm-install.sh
        exit $?
fi
