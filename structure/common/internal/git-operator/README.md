gitweb:
    - ingress
hooker:
    - rw, /var/lib/git
    - cp hooks on change

remote-fetcher:
    - rw, /var/lib/git
    - daily check for updates
