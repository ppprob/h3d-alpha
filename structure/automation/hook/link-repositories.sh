#!/bin/bash

REPOS=`find $HOME -type  d -name hooks | egrep "common|automation/hook"`

for REPO in $REPOS; do
   [[ -f $REPO/post-receive ]] || \
     ln -s -f -T $HOME/automation/hook/live/post-receive $REPO/post-receive
done

