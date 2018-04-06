#!/usr/bin/env sh

containerd >/var/log/containerd.log 2>&1 &
sleep 1
buildkitd --debug --oci-worker=false --containerd-worker=true >/var/log/buildkitd.log 2>&1 &
sleep 1

exec buildctl "$@"