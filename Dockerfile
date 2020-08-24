FROM stakelovelace/cardano-htn:stage3

ARG DEBIAN_FRONTEND=noninteractive
    
ENV \
    ENV=/etc/profile \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    USER=guild \
    SHELL=/bin/bash \
    CNODE_HOME=/opt/cardano/cnode \
    PATH=/nix/var/nix/profiles/per-user/guild/profile/bin:/nix/var/nix/profiles/per-user/guild/profile/sbin:/opt/cardano/cnode/scripts:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/home/guild/.cabal/bin \
    GIT_SSL_CAINFO=/etc/ssl/certs/ca-certificates.crt \
    NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt \
    NIX_PATH=/nix/var/nix/profiles/per-user/guild/channels

WORKDIR /home/guild

ADD https://raw.githubusercontent.com/stakelovelace/cardano-node/master/master-topology.sh ./
ADD https://raw.githubusercontent.com/stakelovelace/cardano-node/master/ip2loc.sh ./
ADD https://raw.githubusercontent.com/stakelovelace/cardano-node/master/guild-topology.sh ./
ADD https://raw.githubusercontent.com/stakelovelace/cardano-node/master/block_watcher.sh ./
ADD https://raw.githubusercontent.com/stakelovelace/cardano-node/master/entrypoint.sh ./
RUN sudo chown -R guild:guild /home/guild/* \
 && sudo chown -R guild:guild /home/guild/.* \
 && sudo chmod a+x /home/guild/*.sh \
 && sudo chown -R guild:guild $CNODE_HOME/*
    
USER guild

ENTRYPOINT ["./entrypoint.sh"]
