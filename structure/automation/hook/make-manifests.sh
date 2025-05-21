#!/bin/bash


cat << EOF > manifests/git-hooks.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: git-hooks
  namespace: source-system
data:
  post-receive: |
`sed 's/^/    /' post-receive`
EOF

