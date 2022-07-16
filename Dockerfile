FROM golang:1.18
#FROM golang:1.16.3

RUN apt-get update

RUN apt-get upgrade -y


RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get -yq install apt-utils

RUN apt-get install -y \
    openssh-client \
	ca-certificates \
	tar \
	gzip \
	zip \
	python-pip \
	lsb-release \
	shellcheck \
	bats

RUN go get -d github.com/jstemmer/go-junit-report

RUN go get -d honnef.co/go/tools/cmd/staticcheck


RUN export DOCKER_VERSION=$(curl --silent --fail --retry 3 https://download.docker.com/linux/static/stable/x86_64/ | grep -o -e 'docker-[.0-9]*-ce\.tgz' | sort -r | head -n 1) \
    && DOCKER_URL="https://download.docker.com/linux/static/stable/x86_64/${DOCKER_VERSION}" \
    && echo Docker URL: $DOCKER_URL \
    && curl --silent --show-error --location --fail --retry 3 --output /tmp/docker.tgz "${DOCKER_URL}" \
    && ls -lha /tmp/docker.tgz \
    && tar -xz -C /tmp -f /tmp/docker.tgz \
    && mv /tmp/docker/* /usr/bin \
    && rm -rf /tmp/docker /tmp/docker.tgz linux-amd64 \
    && pip install --upgrade awscli


WORKDIR /usr/src/app

COPY tools/* /tools/
# pre-copy/cache go.mod for pre-downloading dependencies and only redownloading them in subsequent builds if they change
COPY go.mod go.sum ./
RUN go mod download && go mod verify

COPY . .
RUN go build -v -o /usr/local/bin/app ./...

CMD ["app"]
