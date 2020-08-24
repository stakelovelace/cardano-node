FROM debian

ARG DEBIAN_FRONTEND=noninteractive

COPY --from=stakelovelace/cardano-htn:stage3 /etc /etc
COPY --from=stakelovelace/cardano-htn:stage3 /nix /nix
COPY --from=stakelovelace/cardano-htn:stage3 /bin /bin
COPY --from=stakelovelace/cardano-htn:stage3 /sbin /sbin
COPY --from=stakelovelace/cardano-htn:stage3 /usr/lib /usr/lib
COPY --from=stakelovelace/cardano-htn:stage3 /lib /lib
COPY --from=stakelovelace/cardano-htn:stage3 /lib64 /lib64
COPY --from=stakelovelace/cardano-htn:stage3 /usr/local/bin /usr/local/bin
COPY --from=stakelovelace/cardano-htn:stage3 /home/guild /home/guild
COPY --from=stakelovelace/cardano-htn:stage3 /opt/cardano /opt/cardano

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
RUN chown -R guild:guild /home/guild/* \
 && chown -R guild:guild /home/guild/.* \
 && chmod a+x /home/guild/*.sh \
 && chown -R guild:guild $CNODE_HOME/*
    
USER guild

ENTRYPOINT ["./entrypoint.sh"]
