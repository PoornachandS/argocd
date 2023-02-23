#!/bin/bash
sudo -i
apt-get update -y
# add google repo
sudo apt-get install - apt-transport-https ca-certificates gnupg -y
echo "deb [signed=by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list"

sudo apt-get install kubectl

sudo apt-get install -y git jq kubectl google-cloud-sdk-gke-gcloud-auth-plugin
echo 'source /usr/share/bash-completion/bash_completion' >>/root/.bashrc
echo 'export USE_GKE_CLOUD_AUTH_PLUGIN=True' >> /root/.bashrc 

#kubectl
echo 'source <(kubectl completion bash)' >>/root/.bashrc
kubectl completion bash > /etc/bash_completion.d/kubectl

#kustomize
curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash

# Kubectl authentication plugin installation
# https://cloud.google.com/blog/products/containers-kubernetes/kubectl-auth-changes-in-gke


# ln -sf /opt/kubectx/completion/kubens.bash /etc/bash_completion.d/kubens
# ln -sf /opt/kubectx/completion/kubectx.bash /etc/bash_completion.d/kubectx

export USE_GKE_GCLOUD_AUTH_PLUGIN=True
gcloud container clusters get-credentials app-cluster --zone=us-central1

# #kubec 
# 1. Install Argo CD¶
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml


# # To access argocd UI we portforward
kubectl port-forward -n argocd services/argocd-server 8080:443

########################################################################
##################################################################




