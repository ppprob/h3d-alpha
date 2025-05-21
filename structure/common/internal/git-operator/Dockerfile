FROM bash:5.2.37

RUN	apk --no-cache --update add \
	git \
    rsync yq \
    lighttpd perl-cgi fcgiwrap spawn-fcgi highlight pandoc 

RUN wget https://get.helm.sh/helm-v3.17.3-linux-amd64.tar.gz -qO - | tar -xz linux-amd64/helm -C /usr/local/bin --strip-components=1

COPY gitweb/ /
COPY scripts/ /scripts/

ENTRYPOINT ["/scripts/entry.sh"]
