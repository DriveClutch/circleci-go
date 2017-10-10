FROM golang:1.8

RUN apt-get update \
    && apt-get install -y \
	  openssh-client \
	  ca-certificates \
	  tar \
	  gzip \
	  python-pip \
    && curl https://glide.sh/get | sh \
    && go get github.com/jstemmer/go-junit-report \
    && export DOCKER_VERSION=$(curl --silent --fail --retry 3 https://download.docker.com/linux/static/stable/x86_64/ | grep -o -e 'docker-[.0-9]*-ce\.tgz' | sort -r | head -n 1) \
    && DOCKER_URL="https://download.docker.com/linux/static/stable/x86_64/${DOCKER_VERSION}" \
    && echo Docker URL: $DOCKER_URL \
    && curl --silent --show-error --location --fail --retry 3 --output /tmp/docker.tgz "${DOCKER_URL}" \
    && ls -lha /tmp/docker.tgz \
    && tar -xz -C /tmp -f /tmp/docker.tgz \
    && mv /tmp/docker/* /usr/bin \
    && curl -LO https://s3.amazonaws.com/chartmuseum/release/latest/bin/linux/amd64/chartmuseum \
    && chmod +x ./chartmuseum \
    && mv ./chartmuseum /usr/bin/ \
    && curl -LO https://kubernetes-helm.storage.googleapis.com/helm-v2.6.2-linux-amd64.tar.gz \
    && tar -xzvf helm-v2.6.2-linux-amd64.tar.gz \
    && mv linux-amd64/helm /usr/bin/helm \
    && rm -rf /tmp/docker /tmp/docker.tgz linux-amd64 \
    && pip install --upgrade awscli

COPY tools/* /tools/
