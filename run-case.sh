#!/bin/bash
set -x

echo "# Test case [$1]"

CASE_DIR="$1"

export AWS_REGION=${AWS_REGION:-$(aws configure get region)}
export CLUSTER_NAME=${CLUSTER_NAME:-"$USER$(date +%m%d%H%M)"}
export CLUSTER_DIR=".run/$CLUSTER_NAME"
export SSH_KEY=$(cat $HOME/.ssh/id_rsa.pub)

mkdir -p $CLUSTER_DIR
envsubst < $CASE_DIR/install-config.env.yaml > $CLUSTER_DIR/install-config.yaml
cp $CLUSTER_DIR/install-config.yaml $CLUSTER_DIR/install-config.bak.yaml

aws sts get-caller-identity
sleep 30

openshift-install create cluster --dir=$CLUSTER_DIR
echo done

