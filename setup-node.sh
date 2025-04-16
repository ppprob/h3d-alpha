#!/bin/bash

DIR_GIT=/home/bob/tmp/test-init/dirgit
DIR_REGISTRY=/var/lib/registry

source package-system-index

init_git () {
    for repo in `find structure -maxdepth 5 -type f -exec dirname {} \; | sort | uniq`;
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

# tar reg.tgz

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
    cp -r structure/common/internal/cluster-k8s-base/chart/* structure/cluster/local/
    sed -i "s#<pathtogit>#$DIR_GIT#" structure/cluster/local/templates/bootstrap/run-init.sh
    sed -i "s#k8sVersion:#k8sVersion: ${SYSBIN[kubernetes]}#" structure/cluster/local/values.yaml
}

template_local
