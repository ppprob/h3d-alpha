#!/bin/bash

mkdir -p bootstrap
mkdir -p cluster-layer-0

WRITE_TO=""
while IFS='' read line; do
    if [[ -n $WRITE_TO ]]; then
        if [[ -n `grep '# Source:' <<< $line` ]]
        then
            # Change WRITE_TO if different
            [[ $WRITE_TO != ${line##*templates/} ]] \
              && sed -i '$d' $WRITE_TO \
              && WRITE_TO=${line##*templates/} \
              && > $WRITE_TO
        else
            echo "$line" >> $WRITE_TO
        fi
    else
        # Set WRITE_TO if empty
        [[ -n `grep '# Source:' <<< $line` ]] \
          && WRITE_TO=${line##*templates/} \
          && > $WRITE_TO
    fi
done <<< `helm template no-name . --debug 2> /dev/null`

cat << EOF > bootstrap/.gitignore
flux-variables.yaml
gotk-sync.yaml
EOF

sed '/stringData/,$ s/:.*/:/' bootstrap/flux-variables.yaml > bootstrap/flux-variables.yaml.tmpl

chmod +x bootstrap/run-init.sh
chmod +x bootstrap/create-ca.sh

rm -rf Chart.yaml templates values.yaml unfold.sh
