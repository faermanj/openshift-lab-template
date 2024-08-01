#!/bin/bash
set -x

echo "Executing test case [$1]"

export CASE_NAME="$1"
export CASE_DIR="$CASE_NAME"

export CLUSTER_PREFIX=${CLUSTER_PREFIX:-$USER}
export AWS_REGION=${AWS_REGION:-$(aws configure get region)}
export CLUSTER_NAME=${CLUSTER_NAME:-"$CLUSTER_PREFIX-$CASE_NAME-$(date +%m%d%H%M)"}
export CLUSTER_DIR=".run/$CLUSTER_NAME"
export SSH_KEY=$(cat $HOME/.ssh/id_rsa.pub)

echo "Generating cluster configuration for case [$1]..."
mkdir -p $CLUSTER_DIR
envsubst < $CASE_DIR/install-config.env.yaml > $CLUSTER_DIR/install-config.yaml
cp $CLUSTER_DIR/install-config.yaml $CLUSTER_DIR/install-config.bak.yaml

mkdir -p "$CLUSTER_DIR/log"

if [ -f "$CLUSTER_DIR/before-create.sh" ]; then
    echo "Executing before-create hook [$CLUSTER_DIR/before-create.sh]"
    source "$CLUSTER_DIR/before-create.sh" | tee tee $CLUSTER_DIR/log/before-create.log.txt
fi

echo "Case [$1][$(date)] creating cluster..."
time openshift-install create cluster --dir=$CLUSTER_DIR | tee $CLUSTER_DIR/log/create-cluster.log.txt

echo "Case [$1][$(date)] cluster created."

export KUBECONFIG=$CLUSTER_DIR/auth/kubeconfig
oc status | tee $CLUSTER_DIR/log/oc-status.log.txt


echo "Executing test..."
sleep 15

if [ -f "$CLUSTER_DIR/case-main.sh" ]; then
    echo "Executing main case hook [$CLUSTER_DIR/case-main.sh]"
    source "$CLUSTER_DIR/case-main.sh" | tee $CLUSTER_DIR/log/case-main.log.txt
fi

echo "Case [$1][$(date)] collecting must gather..."
oc adm must-gather | tee $CLUSTER_DIR/log/must-gather.log.txt


echo "Case [$1] destroy cluster..."
openshift-install destroy cluster --dir=$CLUSTER_DIR | tee $CLUSTER_DIR/log/destroy-cluster.log.txt

echo "Case [$1] considering pruning..."
if [ -f "$CLUSTER_DIR/case-prune.sh" ]; then
    echo "Executing prune case hook [$CLUSTER_DIR/case-prune.sh]"
    source "$CLUSTER_DIR/case-prune.sh" | tee $CLUSTER_DIR/log/case-prune.log.txt
fi


echo "Case [$1] done!"

