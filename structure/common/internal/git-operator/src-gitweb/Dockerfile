FROM alpine:3.21.3

RUN	apk --no-cache --update add \
	git \
	perl-cgi \
	fcgiwrap \
	spawn-fcgi \
	highlight \
	pandoc \
    lighttpd

COPY gitweb.conf /etc/gitweb.conf
COPY lighttpd.conf /etc/lighttpd/lighttpd.conf

COPY usr/ /usr/share/gitweb/

CMD ["lighttpd","-D","-f","/etc/lighttpd/lighttpd.conf"]
