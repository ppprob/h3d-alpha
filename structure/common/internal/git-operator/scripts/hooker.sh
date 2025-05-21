#!/usr/bin/env bash

#REPO_GROUPS='common/external common/internal'
#GIT_PATH=/var/lib/git

function getRepos () {
    REPOS=""
    for repo in $REPO_GROUPS
    do
        REPOS="$REPOS `find ${GIT_PATH}/${repo} -mindepth 1 -maxdepth 1 -type d`"
    done
}

function copyHooks () {
    for repo in $REPOS
    do
        cp -L /mnt/hooks/* $repo/hooks/
    done
}

function getCMTimestamp () {
    ls -la /mnt/hooks | grep -Eom 1 '[0-9]{4}_[0-9_.]+$' 
}

CM_DATE=$(getCMTimestamp)

getRepos
CURRENT_REPOS=$REPOS

echo "+ Start with unconditional copy"
copyHooks

while true 
do
    getRepos
    if [[ "$CURRENT_REPOS" != "$REPOS" ]]
    then
        echo "+ New repo, copy again"
        # repos=diff
        copyHooks
        CURRENT_REPOS="$REPOS"
    fi
    if [[ $CM_DATE != `getCMTimestamp` ]]
    then
        echo "+ Change in hooks, copy again"
        copyHooks
        CM_DATE=$(getCMTimestamp)
    fi
    sleep 30
done
