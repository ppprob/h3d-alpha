#!/bin/bash

CASUBJ='/CN=h3d Root CA/C=HU/ST=Pest/L=Budapest/O=cluster-local'
REGSUBJ='/CN=registry/C=HU/ST=Pest/L=Budapest/O=cluster-local'
REGALTNAME='subjectAltName = DNS: registry.source-system'

mkdir -p pki

echo "+ Create CA"
openssl genrsa -aes256 -passout pass:password -out pki/cluster-ca.key.passwd 4096
openssl rsa -in pki/cluster-ca.key.passwd -passin pass:password -out pki/cluster-ca.key
rm -f pki/cluster-ca.key.passwd
openssl req -x509 -new -nodes -key pki/cluster-ca.key -sha256 -days 1826 -out pki/cluster-ca.crt -subj "$CASUBJ"

echo "+ Create non-cert-manager registry certificate"
openssl genrsa -aes256 -passout pass:password -out pki/registry.key.passwd 4096
openssl rsa -in pki/registry.key.passwd -passin pass:password -out pki/registry.key
rm -f pki/registry.key.passwd

openssl req -x509 -CAkey pki/cluster-ca.key -CA pki/cluster-ca.crt -sha256 -days 365 -key pki/registry.key -out pki/registry.crt -subj "$REGSUBJ" -passout pass: -addext "$REGALTNAME" \
                   -addext "basicConstraints = critical,CA:FALSE" \
                   -addext "keyUsage = critical, digitalSignature, keyEncipherment" \
                   -addext "extendedKeyUsage = clientAuth, serverAuth"

echo "+ Insert CA values to flux-variables.yaml"
sed -i "s/clusterCA__cert_b64: /clusterCA__cert_b64: `base64 -w0 pki/cluster-ca.crt`/" flux-variables.yaml
sed -i "s/clusterCA__key_b64: /clusterCA__key_b64: `base64 -w0 pki/cluster-ca.key`/" flux-variables.yaml

echo "IMPORT CA FOR THE HOST!"

echo "*.key" > pki/.gitignore
