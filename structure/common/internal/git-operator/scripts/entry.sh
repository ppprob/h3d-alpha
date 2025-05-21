#!/usr/bin/env bash

CMD=$1

case $CMD in
    serve)
        lighttpd -D -f /etc/lighttpd/lighttpd.conf
    ;;
    hook)
       /scripts/hooker.sh
    ;;
    fetch)
        /scripts/fetcher.sh
    ;;
esac
