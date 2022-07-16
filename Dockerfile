FROM golang:1.17.3-stretch

RUN apt-get -yq update && apt-get -yq upgrade

RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get -yq install apt-utils


RUN apt-get -yq install \
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
    	bats \
    	golang-glide \
    && apt-get -yq clean \
    && rm -rf /var/lib/apt/lists/*


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
    && pip3 install --upgrade awscli


COPY tools/* /tools/
