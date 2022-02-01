#!/bin/bash
set -e

export INSTALL_RKE2_TYPE="${type}"
#export INSTALL_RKE2_VERSION="${rke2_version}"

if [ "$${DEBUG}" == 1 ]; then
  set -x
fi

# info logs the given argument at info log level.
info() {
    echo "[INFO] " "$@"
}

# warn logs the given argument at warn log level.
warn() {
    echo "[WARN] " "$@" >&2
}

# fatal logs the given argument at fatal log level.
fatal() {
    echo "[ERROR] " "$@" >&2
    exit 1
}

download_and_install() {
  curl -sfL https://get.rke2.io | sh -
}

{
  download_and_install
}
