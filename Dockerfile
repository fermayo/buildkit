FROM golang:1.10-alpine3.7 AS build-buildkit
RUN apk --no-cache add curl build-base
WORKDIR /go/src/github.com/moby/buildkit
COPY . /go/src/github.com/moby/buildkit
RUN go install -v ./cmd/buildctl
RUN go install -v ./cmd/buildkitd

FROM golang:1.10-alpine3.7 AS build-containerd
RUN apk --no-cache add git curl build-base btrfs-progs-dev linux-headers
ENV CONTAINERD_VERSION=1.0.3
RUN go get -d -v github.com/containerd/containerd
WORKDIR /go/src/github.com/containerd/containerd
RUN git checkout v${CONTAINERD_VERSION} && make

FROM golang:1.10-alpine3.7 AS build-runc
RUN apk --no-cache add bash git curl build-base libseccomp-dev
ENV RUNC_VERSION=1.0.0-rc5
RUN go get -d -v github.com/opencontainers/runc
WORKDIR /go/src/github.com/opencontainers/runc
RUN git checkout v${RUNC_VERSION}
RUN make runc

FROM golang:1.10-alpine3.7
RUN apk --no-cache add git xfsprogs e2fsprogs btrfs-progs libseccomp jq
ENV AWS_REGION=us-east-1
WORKDIR /go/src/github.com/moby/buildkit
ENTRYPOINT ["entrypoint.sh"]
VOLUME /var/lib
COPY --from=build-buildkit /go/bin/* /usr/local/bin/
COPY --from=build-containerd /go/src/github.com/containerd/containerd/bin/* /usr/local/bin/
COPY --from=build-runc /go/src/github.com/opencontainers/runc/runc /usr/local/bin/runc
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
