#!/bin/bash

SOURCE="<pathtogit>/bin/package-system"

install_pkgs () {
    echo "+ Installing system biniaries"

    rsync -rlpv $SOURCE/ /

    sysctl --system
    systemctl daemon-reload
    systemctl start containerd
    systemctl start kubelet 
}

init_k8s () {
    echo "+ Initializing Kubernetes"
    if [[ ! -f kubeadm-config.yaml ]];
    then
        echo "Error: Create the .yaml files from the templates first"
        exit 1
    fi

    kubeadm init --config kubeadm-config.yaml --ignore-preflight-errors FileExisting-iptables
    mkdir -p /root/.kube
    cp /etc/kubernetes/super-admin.conf /root/.kube/config
    # Install network add-on
    # helm install cilium https://helm.cilium.io/cilium-1.17.2.tgz -f cilium.yaml -n network-system --create-namespace
}

init_flux () {
    echo "+ Installing flux and bootstrap"
    if [[ ! -f flux-variables.yaml ]];
    then
        echo "Error: Create the .yaml files from the templates first"
        exit 1
    fi

    # touch gitignore && commit push

    kubectl create -f ../cluster-layer-0/gotk-components.yaml
    kubectl create -f flux-variables.yaml
    kubectl create -f gotk-sync.yaml
}

if [[ `id -u` -ne  0 ]];
then 
    echo "Run as root!"
    exit 1
fi

case $1 in
    all)
        install_pkgs
        init_k8s
        init_flux
    ;;
    install_pkgs)
        install_pkgs
    ;;
    init_k8s)
        init_k8s
    ;;
    init_flux)
        init_flux
    ;;
    *)
        echo "all | install_pkgs | init_k8s | init_flux"
    ;;
esac
