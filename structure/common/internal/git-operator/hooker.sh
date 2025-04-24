#!/bin/bash

REPO_GROUPS='common/external common/internal'
GIT_PATH=/mnt/git

for repo in $REPO_GROUPS
do
    REPOS="$REPOS `find ${GIT_PATH}/${repo} -mindepth 1 -maxdepth 1 -type d`"
done

function copy_hooks () {
    for repo in $REPOS
    do
        cp -L /mnt/hooks/* $repo/hooks/
    done
}

function get_CM_DATE () {
    ls -la /mnt/hooks | grep -Eom 1 '[0-9]{4}_[0-9_.]+$' 
}

echo "+ Start with unconditional copy"
copy_hooks

CM_DATE=$(get_CM_DATE)

while true 
do
    if [[ $CM_DATE != `get_CM_DATE` ]]
    then
        echo "+ Change in hooks, copy again"
        copy_hooks
        CM_DATE=$(get_CM_DATE)
    fi
    sleep 30
done
