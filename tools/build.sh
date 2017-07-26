#!/bin/bash -eo pipefail

CGO_ENABLED=0 go build -a -installsuffix cgo -ldflags "-s -X main.buildinfobuildtime=$(date '+%Y-%m-%d_%I:%M:%S%p') -X main.buildinfogithash=${GITHASH} -X main.buildinfoversion=${TAGVERSION-latest}"
