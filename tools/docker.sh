#!/bin/bash -e

MY_EXCLUDES=""
BASE_DIR=""

while getopts "d:x:" OPT; do
	case $OPT in
		d)
			BASE_DIR="$OPTARG"
			;;
		x)
			MY_EXCLUDES="${MY_EXCLUDES} $OPTARG"
			;;
	esac
done
shift $(($OPTIND -1))
# Trim leading space from excludes
MY_EXCLUDES="${MY_EXCLUDES## }"

if [[ -f ".circleci/debuglog" ]]; then
	set -x
fi

if [[ -x "tools/docker.sh" ]]; then
	tools/docker.sh
	exit $?
fi

ECR_HOSTNAME="458132236648.dkr.ecr.us-east-1.amazonaws.com"
export AWS_DEFAULT_REGION="us-east-1"

function setup_ecr_repo() {
  local doremote=$1
  local app=$2
  local repo=$3

  local POLICY_FILENAME="ecrpolicy.json"

  cat <<EOM > ${POLICY_FILENAME}
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "newaccounts",
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "arn:aws:iam::473953882568:root",
          "arn:aws:iam::882831108660:root",
          "arn:aws:iam::543661694755:root",
          "arn:aws:iam::790280700559:root",
          "arn:aws:iam::693451398936:root",
          "arn:aws:iam::183927706744:root",
          "arn:aws:iam::597078432132:root"
        ]
      },
      "Action": [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability"
      ]
    }
  ]
}
EOM

  if $doremote; then
    echo "${app} Checking for ECR repo ${repo}"
    set +e # Turn off failure dumping
    aws ecr describe-repositories --repository-name ${repo}
    RET=$?
    set -e # Turn on failure dumping
    if [ "$RET" != "0" ]; then
      echo "${app} Did not find repo, creating ${repo}"
      aws ecr create-repository --repository-name ${repo}
    fi
    echo "${app} Setting repo policy"
    aws ecr set-repository-policy --repository-name ${repo} --policy-text file://${POLICY_FILENAME}
  fi
}

function docker_build_tag_push() {
  local doremote=$1
  local app=$2
  local builddir=$3
  local hashedimagetag=$4
  local latestimagetag=$5

  echo "${app} Building docker image"
  docker build                               \
	  -t ${hashedimagetag}                   \
	  -t ${latestimagetag}                   \
	  ${builddir}

  if $doremote; then
    echo "Pushing ${hashedimagetag} to ECR"
    docker push ${hashedimagetag}
    echo "Pushing ${latestimagetag} to ECR"
    docker push ${latestimagetag}
  fi
}


# Figure out where we are and if we should be interacting with ECR
DOREMOTE=false
if [[ ! -z $CIRCLE_BUILD_NUM && ( $CIRCLE_BRANCH == "develop" || $CIRCLE_BRANCH == "master" || $CIRCLE_BRANCH =~ "hotfix"* || $CIRCLE_BRANCH =~ "release"* ) ]]; then
	DOREMOTE=true
else
    echo "*NOT* interacting with ECR, either because branchname is not appropriate or not actually in a circleci environment"
fi

echo "
BuildNum: $CIRCLE_BUILD_NUM
Branch: $CIRCLE_BRANCH
DOREMOTE: $DOREMOTE
"

if $DORREMOTE; then
    # Login to the ECR repo
    eval $(aws ecr get-login --no-include-email)
fi

if [[ -z "$BASE_DIR" ]]; then
	MY_BASE_DIR=.
else
	MY_BASE_DIR="${BASE_DIR%/}"
fi

list_dockerfiles() {
	MY_DS=$(find $MY_BASE_DIR -not -path "$MY_BASE_DIR/vendor/*" -not -path "$MY_BASE_DIR/node_modules/*" -name Dockerfile)
	for excl in $MY_EXCLUDES; do
		MY_DS=$(echo $MY_DS | tr " " "\n" | grep -v $excl)
	done
	echo $MY_DS
}

# Look for all the Dockerfiles, exclude the vendor directory for Go projects and node_modules for NodeJS projects
for dockerfile in $(list_dockerfiles); do
	# Use the parent directory of the Dockerfile as the appname
	appname=$(basename $(dirname $dockerfile))
	# Set the relative path to the Dockerfile for building
	dockerdir=$(dirname $dockerfile)

	if [[ -f "$dockerdir/.noautobuild" ]]; then
		continue
	fi

	if [[ $appname == "." ]]; then
		# Dockerfile is at the repo root, update the appname to the name of the repo
		appname=$(basename $PWD)
	else
		# If the appname is not "." then it is not in the root of the repo, so add a slash to the dockerdir
		dockerdir="${dockerdir}/"
	fi

	# set the name of the ecr repo inside the registry
	ecrreponame="${CIRCLE_BRANCH:-master}/${appname}"
	# Set the fully qualified repo rul
	urlbase="${ECR_HOSTNAME}/${ecrreponame}"
	# Set the git hash of the build (NOTE: using localbuild for non CircleCI builds on purpose)
	buildhash=${CIRCLE_SHA1:-localbuild}

	# Make sure the repo exists and has the correct pull permissions for all the accounts
	setup_ecr_repo $DOREMOTE ${appname} ${ecrreponame}
	# Build the Docker and push it to ECR
	docker_build_tag_push $DOREMOTE ${appname} ${dockerdir} ${urlbase}:${buildhash} ${urlbase}:latest
done
