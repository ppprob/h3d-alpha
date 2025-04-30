#!/bin/bash

DIR_GIT=/var/lib/git
DIR_REGISTRY=/var/lib/registry

source index/package-system

init_git () {
    rm -rf .git
    echo "+ Initialize git structure"
    for repo in `find structure -name .gitignore -type f -exec dirname {} \; | sort | uniq`
    do
        repo=${repo#*/}
        git init -q --bare -b master $DIR_GIT/$repo
        git init -q -b master structure/$repo

        cd structure/$repo
        git add . && git commit -aqm 'init'
        git remote add origin $DIR_GIT/$repo
        git push origin master
        cd -
    done
}

extract_registry () {
    echo "+ Extract registry content" 
    mkdir $DIR_REGISTRY
    tar -C $DIR_REGISTRY -xzf registry.tgz
}

pull_binaries () {
    for bin in ${!SYSBIN[@]}
    do
        echo " + Pulling $bin=${SYSBIN[$bin]} binaries"
        ./structure/bin/system/${bin}/post-merge ${SYSBIN[$bin]}
    done
    mv root $DIR_GIT/bin/package-system
}

# package-user-index, currently helm in bin/system

template_local () {
    echo "+ Copy cluster template chart to cluster/local"
    cp -r structure/common/internal/cluster-k8s-base/chart/* structure/cluster/local/
    sed -i "s#<pathtogit>#$DIR_GIT#" structure/cluster/local/templates/bootstrap/run-init.sh
    sed -i "s#k8sVersion:#k8sVersion: ${SYSBIN[kubernetes]}#" structure/cluster/local/values.yaml
}

init_git
extract_registry
pull_binaries
template_local
