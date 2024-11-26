#!/bin/bash

curl -sfL https://get.k3s.io | sh -s - server \
    --tls-san $LB_DOMAIN_NAME \
    --tls-san $NODE_PRIV_IP \
    --node-external-ip $LB_PUB_IP \
    --cluster-init

curl -sfL https://get.k3s.io | sh -s - server \
    --server https://${SERVER_PRIV_IP}:6443 \
    --token $JOIN_TOKEN

curl -sfL https://get.k3s.io | sh -s - agent \
    --server https://${SERVER_PRIV_IP}:6443 \
    --token $JOIN_TOKEN

# kubeconfig is at /etc/rancher/k3s/k3s.yaml 
# token is at /var/lib/rancher/k3s/server/node-token

# oci session refresh --profile DEFAULT

# mv k3s.yml ~/.kube/config