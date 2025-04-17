    echo "+ Initialize git structure"
    for repo in `find structure -name .gitignore -type f -exec dirname {} \; | sort | uniq`;
    do
        repo=${repo#*/}
        echo $repo
    done
