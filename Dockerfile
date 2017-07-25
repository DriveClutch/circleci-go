FROM golang:1.8.3

#RUN apt-get update && \
#    apt-get install -y software-properties-common python-software-properties && \
#    add-apt-repository -y ppa:masterminds/glide -y && \
#    apt-get update && \
#    apt-get install -y glide && \
#	apt-get remove software-properties-common python-software-properties && \
#	rm -rf \
#	  /var/cache/apk/* \
#	  /tmp/* \
#	  && \
#	go get github.com/jstemmer/go-junit-report

RUN apt-get update \
    && apt-get install -y \
	  openssh-client \
	  ca-certificates \
	  tar \
	  gzip \
	  python-pip \
	&& curl https://glide.sh/get | sh \
    && go get github.com/jstemmer/go-junit-report \
	&& export DOCKER_VERSION=$(curl --silent --fail --retry 3 https://get.docker.com/builds/  | grep -P -o 'docker-\d+\.\d+\.\d+-ce\.tgz' | head -n 1) \
    && DOCKER_URL="https://get.docker.com/builds/Linux/x86_64/${DOCKER_VERSION}" \
    && echo Docker URL: $DOCKER_URL \
    && curl --silent --show-error --location --fail --retry 3 --output /tmp/docker.tgz "${DOCKER_URL}" \
    && ls -lha /tmp/docker.tgz \
    && tar -xz -C /tmp -f /tmp/docker.tgz \
    && mv /tmp/docker/* /usr/bin \
    && rm -rf /tmp/docker /tmp/docker.tgz \
	&& pip install --upgrade --user awscli
