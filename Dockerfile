FROM golang:1.18
#FROM golang:1.16.3

RUN sudo apt-get -yq update && sudo apt-get -yq upgrade

RUN export DEBIAN_FRONTEND=noninteractive && \
    sudo apt-get -yq install apt-utils


RUN sudo apt-get -yq install \
        ca-certificates \
        curl \
        git \
        openssh-client \
    	tar \
    	gzip \
    	zip \
    	python3-pip \
    	lsb-release \
    	shellcheck \
    	bats\
    && sudo apt-get -yq clean \
    && sudo rm -rf /var/lib/apt/lists/*


RUN export PATH=$PATH:/usr/local/go/bin

RUN go install github.com/jstemmer/go-junit-report@latest

RUN go install honnef.co/go/tools/cmd/staticcheck@latest


RUN export DOCKER_VERSION=$(curl --silent --fail --retry 3 https://download.docker.com/linux/static/stable/x86_64/ | grep -o -e 'docker-[.0-9]*-ce\.tgz' | sort -r | head -n 1) \
    && DOCKER_URL="https://download.docker.com/linux/static/stable/x86_64/${DOCKER_VERSION}" \
    && echo Docker URL: $DOCKER_URL \
    && curl --silent --show-error --location --fail --retry 3 --output /tmp/docker.tgz "${DOCKER_URL}" \
    && ls -lha /tmp/docker.tgz \
    && tar -xz -C /tmp -f /tmp/docker.tgz \
    && mv /tmp/docker/* /usr/bin \
    && rm -rf /tmp/docker /tmp/docker.tgz linux-amd64 \
    && pip install --upgrade awscli


#WORKDIR /usr/src/app

COPY tools/* /tools/
# pre-copy/cache go.mod for pre-downloading dependencies and only redownloading them in subsequent builds if they change
#COPY go.mod go.sum ./
#RUN go mod download && go mod verify
#
#COPY . .
#RUN go build -v -o /usr/local/bin/app ./...
#
#CMD ["app"]
