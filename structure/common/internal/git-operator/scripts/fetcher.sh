#!/usr/bin/env bash

#REPO_GROUPS='common/external common/internal bin/system'
#GIT_PATH=/var/lib/git

function getRepos () {
    REPOS=""
    for repo in $REPO_GROUPS
    do
        REPOS="$REPOS `find ${GIT_PATH}/${repo} -mindepth 1 -maxdepth 1 -type d`"
    done
}

function reportUpdate () {
    if [[ -n "`git ls-remote $REPO | grep new-version`" ]]
    then
        echo "report update for $REPO"
    fi
}

# HELP cert_checker_expiration Certification expiration in hours
# TYPE cert_checker_expiration gauge
# cert_checker_expiration{host=\"%s\",subject=\"%s\"} %d\n"

getRepos
CURRENT_REPOS=$REPOS

while true 
do
    getRepos
    TODAY="$(date '+%d')"
    if [[ $DAY != $TODAY ]] || [[ "$CURRENT_REPOS" != "$REPOS" ]]
    then
        echo " ++ Checking for updates"
        for REPO in $REPOS
        do
            echo " + get-new-version - $REPO"
            /scripts/get-new-version.sh $REPO
        done
        DAY=$TODAY
        CURRENT_REPOS="$REPOS"
    else
        for REPO in $REPOS
        do
            reportUpdate
        done
    fi
    sleep 60
done
