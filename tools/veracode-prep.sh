#!/bin/bash -e

while getopts "d:" OPT; do
	case $OPT in
		d)
			BASE_DIR="$OPTARG"
			;;
	esac
done
shift $(($OPTIND -1))

cd $BASE_DIR

go mod vendor