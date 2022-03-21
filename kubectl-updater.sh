#!/bin/bash

KUBECTL_DIR=$HOME/.kubectl
KUBECTL_MAJOR_VER=$(kubectl version --short 2>/dev/null |\
    sed -n 's/Server Version: v\([0-9]*\..[0-9]*\).*/\1/pi')
K8S_CHANGELOG_URL="https://raw.githubusercontent.com/kubernetes/kubernetes/master/CHANGELOG/CHANGELOG-$KUBECTL_MAJOR_VER.md"
KUBECTL_VER=$(curl -L -s $K8S_CHANGELOG_URL |\
    sed -n 's/^- \[\(.*\)\].*/\1/p' |\
    head -n 1)
KUBECTL_FILE=$KUBECTL_DIR/kubectl-$KUBECTL_VER

exit_err() {
   echo >&2 "${1}"
   exit 1
}

if [ ! -f "$KUBECTL_FILE" ]; then
    if [ ! -d "$KUBECTL_DIR" ]; then
        mkdir $KUBECTL_DIR || exit_err "Failed to create $KUBECTL_DIR."
    fi

    KUBECTL_URL="https://dl.k8s.io/release/$KUBECTL_VER/bin/darwin/amd64/kubectl"
    curl -Lo $KUBECTL_FILE $KUBECTL_URL ||\
    exit_err "Failed to download $KUBECTL_URL."
    chmod +x $KUBECTL_FILE
fi


if [ -f "$KUBECTL_FILE" ]; then
    alias k=$KUBECTL_FILE
    alias kubectl=$KUBECTL_FILE
else
    exit_err "Failed to create $KUBECTL_FILE."
fi