#!/bin/bash

args=("$@")

KUBECTL_DIR=$HOME/.kubectl
CACHE_FILE=$KUBECTL_DIR/cache

fallback() {
   echo >&2 "${1}"
   echo >&2 "Fallback to default kubectl"
   kubectl "${args[@]}"
   exit $?
}

init_validation() {
    if [ ! -d "$KUBECTL_DIR" ]; then
        mkdir $KUBECTL_DIR || fallback "Failed to create $KUBECTL_DIR."
    elif [ ! -f "$CACHE_FILE" ]; then
        touch $CACHE_FILE || fallback "Failed to create $CACHE_FILE."
    fi
}

discover_currect_kubectl_version() {
    KUBECTL_MAJOR_VER=$(kubectl version --short 2>/dev/null |\
        sed -n 's/Server Version: v\([0-9]*\..[0-9]*\).*/\1/pi')
    if [[ -z $KUBECTL_MAJOR_VER ]]; then
        fallback "Failed to detect Kubernetes server API version."
    fi
    K8S_CHANGELOG_URL="https://raw.githubusercontent.com/kubernetes/kubernetes/master/CHANGELOG/CHANGELOG-$KUBECTL_MAJOR_VER.md"
    KUBECTL_VER=$(curl -L -s $K8S_CHANGELOG_URL |\
        sed -n 's/^- \[\(.*\)\].*/\1/p' |\
        head -n 1)
    if [[ -z $K8S_CHANGELOG_URL ]]; then
        fallback "Failed to get Kubernetes CHANGELOG."
    fi
}

cach_validation() {
    eval $(cat $CACHE_FILE)
    current_context=$(kubectl config current-context)
    if [[ $cached_context == $current_context ]]; then
        echo equal! cached_version=$cached_version
        KUBECTL_VER=$cached_version
    else
        echo not equal! cached_version=$cached_version
        discover_currect_kubectl_version
        echo cached_context=$current_context > $CACHE_FILE || fallback "Failed to edit $CACHE_FILE."
        echo cached_version=$KUBECTL_VER >> $CACHE_FILE || fallback "Failed to edit $CACHE_FILE."
    fi
    KUBECTL_FILE=$KUBECTL_DIR/kubectl-$KUBECTL_VER
}

get_kubectl() {
    KUBECTL_URL="https://dl.k8s.io/release/$KUBECTL_VER/bin/darwin/amd64/kubectl"
    curl -f -Lo $KUBECTL_FILE $KUBECTL_URL || fallback "Failed to download $KUBECTL_URL."
    chmod +x $KUBECTL_FILE || fallback "Failed to set permissions to $KUBECTL_FILE."
}

kubectl_existence_validation() {
    if [ ! -f "$KUBECTL_FILE" ]; then
        get_kubectl
    fi
}

init_validation
cach_validation
kubectl_existence_validation

$KUBECTL_FILE "${args[@]}"
exit $?