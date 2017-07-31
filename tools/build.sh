#!/bin/bash -e

CGO_ENABLED=0 go build -a -installsuffix cgo -ldflags "-s -X main.buildinfobuildtime=$(date '+%Y-%m-%d_%I:%M:%S%p') -X main.buildinfogithash=${CIRCLE_SHA1} -X main.buildinfoversion=${CIRCLE_TAG-latest}"
