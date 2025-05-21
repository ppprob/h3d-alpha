#!/usr/bin/env bash
# DEP: git,yq,jq,helm,rsync
#set -x

REPO=$1

function setRepoParams {

    # read origin file, exit if not found
    
    originyaml=`git archive --remote $REPO HEAD origin.yaml 2>/dev/null | tar -xO 2>/dev/null` || echo "no origin" && exit

    LOCAL_TAG=`git ls-remote --refs --tags $REPO | awk -F'/' '{print $3}' | sort -V | tail -n1`

    CHART_NAME=`yq -r '.chart.name' <<< $originyaml`
    if [[ $CHART_NAME != null ]]
    then
        CHART_REPOURL=`yq -r '.chart.repoUrl' <<< $originyaml`
        [[ -n `grep 'oci://' <<< $CHART_REPOURL` ]] && HELM_OCI='true' \
                                                    || HELM_OCI='false'
        case $HELM_OCI in
            true)
                CHART_SOURCE=$CHART_REPOURL
                ;;
            false)
                CHART_REPO=`cut -d'/' -f3 <<< $CHART_REPOURL`
                helm repo add $CHART_REPO $CHART_REPOURL
                helm repo update
                CHART_SOURCE="$CHART_REPO/$CHART_NAME" 
                ;;
        esac
    fi
    
    GIT_SOURCE=`yq -r '.git.remote' <<< $originyaml`
    [[ `yq -r '.git.outOfRemoteComponents' <<< $originyaml` != null ]] && \
       GIT_OORC=`yq -r '.git.outOfRemoteComponents | @tsv' <<< $originyaml`
}

function checkRemoteVersions {

    if [[ -n $CHART_SOURCE ]]
    then
        # we have a remote chart, so that's version is our lead
        read version app_version <<< $(
            helm show chart $CHART_SOURCE |\
            yq -r '[.version,.appVersion] | @tsv'
        )
    elif [[ -n $GIT_SOURCE ]]
    then
        # we dont have a remote chart 
        version=`git ls-remote --refs --tags $GIT_SOURCE | awk -F'/' '{print $3}' | sort -V | grep -E "^[v]?[0-9]+.[0-9]+.[0-9]+[^-]*$" | tail -n1`
    else
        echo "we have nothing" && exit
    fi
}

function getNewVersion {

    if [[ -n $CHART_SOURCE ]]
    then
        # Get latest Chart
        helm pull $CHART_SOURCE --untar --untardir import
        # Save previous appVerision if any
        [[ -f chart/Chart.yaml ]] && old_app_version=`yq -r '.appVersion' chart/Chart.yaml`
        rsync -a --checksum --delete import/$CHART_NAME/ chart/
        rm -rf import
        git add . && git commit -q -am "importing Chart $CHART_NAME version: '$version'"

        if [[ $app_version != $old_app_version ]]
        then
            # Get source code
            remote_tag=`git ls-remote --refs --tags $GIT_SOURCE | awk -F'/' '{print $3}' | grep -E "[v]?$app_version$"`
            getNewAppVersion $remote_tag
        fi
    else
        getNewAppVersion $version
    fi
}

function getNewAppVersion {

    remote_tag=$1 
    remote_name=`basename $GIT_SOURCE .git`
    git clone -b "${remote_tag##*/}" --single-branch --depth 1 $GIT_SOURCE import
    rsync -a --checksum --delete --mkpath --exclude='.git' import/ source-code/$remote_name
    rm -rf import
    git add . && git commit -q -am "importing '$remote_name' source-code : '$remote_tag'"  

    for component in $GIT_OORC
    do
        remote_tag=`git ls-remote --refs --tags $component | awk -F'/' '{print $3}' | sort -V | grep -E "^[v]?[0-9]+.[0-9]+.[0-9][^-]*$" | tail -n1`
        remote_name=`basename $component .git`
        git clone -b $remote_tag --single-branch --depth 1 $component import
        rsync -a --checksum --delete --exclude='.git' import/ source-code/$remote_name
        rm -rf import
        git add . && git commit -q -am "importing '$remote_name' source-code : '$remote_tag'"  
    done
}

# --- Run
setRepoParams
checkRemoteVersions
if [[ $version != $LOCAL_TAG ]] && [[ -z `git ls-remote $REPO | grep new-version-$version` ]]
then
    git clone $REPO ./workdir && cd ./workdir
    branch=new-version-$version
    git checkout -b $branch
    getNewVersion
    git push origin $branch
    cd - && rm -rf ./workdir
    
    # create new version alert
#    curl -X POST http://localhost:9093/api/v2/alerts \
#         -H "Content-Type: application/json" \
#         -d "[
#              {
#                \"startsAt\": \"`date +%Y-%m-%dT%H:%M:%S.%3NZ`\",
#                \"endsAt\": \"2025-04-01T23:35:31.456Z\",
#                \"labels\": {
#                    \"alertname\": \"NewVersionToImport\",
#                    \"severity\": \"info\",
#                    \"instance\": \"git\",
#                    \"repository\": \"$REPO\",
#                    \"branch\": \"$branch\"
#                },
#                \"annotations\": {
#                    \"repository\": \"$REPO\",
#                    \"branch\": \"$branch\"
#                }
#              }
#            ]"

else
    echo "+ no upgrade for '$REPO'"
fi
