#!/bin/bash -eo pipefail

# NOTE the $(glide novendor) is to exclude vendor packages testing
go test $(glide novendor)
