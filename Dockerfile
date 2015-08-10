FROM fedora:latest
MAINTAINER Arun Neelicattu <arun.neelicattu@gmail.com>

RUN dnf -y upgrade

# install base requirements
RUN dnf -y install golang git hg

# prepare gopath
ENV GOPATH /go
ENV PATH /go/bin:${PATH}
RUN mkdir -p ${GOPATH}

ENV PACKAGE github.com/elastic/logstash-forwarder
ENV VERSION 0.4.0
ENV GO_BUILD_TAGS netgo
ENV CGO_ENABLED 0

RUN go get ${PACKAGE}

WORKDIR ${GOPATH}/src/${PACKAGE}
RUN git checkout -b v${VERSION} v${VERSION}

RUN go build \
        -tags "${GO_BUILD_TAGS}" \
        -ldflags "-s -w -X ${PACKAGE}/version.Version ${VERSION}" \
        -v -a -installsuffix cgo \
        -o logstash-forwarder

COPY Dockerfile.final ./Dockerfile

CMD docker build -t alectolytic/logstash-forwarder ${PWD}
