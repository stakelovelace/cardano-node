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

# SETUP Guild USER 
RUN adduser --disabled-password --gecos '' guild \
&& echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers \
&& adduser guild sudo \ 
&& chown -R guild:guild /home/guild/.* 

USER guild
WORKDIR /home/guild

ADD https://raw.githubusercontent.com/stakelovelace/cardano-node/master/master-topology.sh ./
ADD https://raw.githubusercontent.com/stakelovelace/cardano-node/master/ip2loc.sh ./
ADD https://raw.githubusercontent.com/stakelovelace/cardano-node/master/guild-topology.sh ./
ADD https://raw.githubusercontent.com/stakelovelace/cardano-node/master/block_watcher.sh ./
ADD https://raw.githubusercontent.com/stakelovelace/cardano-node/master/entrypoint.sh ./
RUN sudo chown -R guild:guild /home/guild/*.sh \
    && sudo chown -R guild:guild $CNODE_HOME/* \
    && sudo chown -R guild:guild /home/guild/.* 
    
ENTRYPOINT ["./entrypoint.sh"]
