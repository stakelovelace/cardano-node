
FROM debian

ARG DEBIAN_FRONTEND=noninteractive

COPY --from=stakelovelace/cardano-htn:stage2 /root/.cabal/bin/* /usr/local/bin/
COPY --from=stakelovelace/cardano-htn:stage2 /usr/lib /usr/lib
COPY --from=stakelovelace/cardano-htn:stage2 /lib /lib
COPY --from=stakelovelace/cardano-htn:stage2 /lib64 /lib64

RUN chmod a+x /usr/local/bin/*

ENV \
    ENV=/etc/profile \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    USER=guild \
    CNODE_HOME=/opt/cardano/cnode \
    PATH=/nix/var/nix/profiles/per-user/guild/profile/bin:/nix/var/nix/profiles/per-user/guild/profile/sbin:/opt/cardano/cnode/scripts:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/home/guild/.cabal/bin \
    GIT_SSL_CAINFO=/etc/ssl/certs/ca-certificates.crt \
    NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt \
    NIX_PATH=/nix/var/nix/profiles/per-user/guild/channels

# PREREQ --no-install-recommends
RUN apt-get update && apt-get install -y curl wget apt-utils xz-utils netbase sudo coreutils dnsutils net-tools procps cron tcptraceroute bc
    
ADD https://raw.githubusercontent.com/stakelovelace/cardano-node/master/promtail.yml /etc/ 
ADD https://raw.githubusercontent.com/stakelovelace/cardano-node/master/promtail /etc/init.d/
ADD https://raw.githubusercontent.com/stakelovelace/cardano-node/master/crontab /etc/cron.d/crontab
RUN chmod a+x /etc/init.d/promtail && chmod 0644 /etc/cron.d/crontab && touch /var/log/cron.log 

# from https://github.com/grafana/loki/releases
RUN cd /usr/local/bin \
&& curl -fSL -o promtail.gz "https://github.com/grafana/loki/releases/download/v1.5.0/promtail-linux-amd64.zip" \
&& gunzip promtail.gz \
&& chmod a+x promtail 

RUN wget https://github.com/javadmohebbi/IP2Location/raw/master/dist/linux/amd64/ip2location \
&& mv ip2location /usr/local/bin/ -v \
&& chmod a+x /usr/local/bin/ip2location -v \
&& /usr/local/bin/ip2location -dl \
&& setcap cap_net_raw=+ep /usr/local/bin/ip2location

RUN cd /usr/bin \
&& sudo wget http://www.vdberg.org/~richard/tcpping \
&& sudo chmod 755 tcpping 

# SETUP Guild USER 
RUN adduser --disabled-password --gecos '' guild \
&& echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers \
&& adduser guild sudo \ 
&& chown -R guild:guild /home/guild/.* \
&& echo "export PATH=/nix/var/nix/profiles/per-user/guild/profile/bin:/nix/var/nix/profiles/per-user/guild/profile/sbin:/opt/cardano/cnode/scripts:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/home/guild/.cabal/bin" >> /home/guild/.bashrc

USER guild
WORKDIR /home/guild

# INSTALL NIX
RUN sudo curl -sL https://nixos.org/nix/install | sh \
    && sudo ln -s /nix/var/nix/profiles/per-user/etc/profile.d/nix.sh /etc/profile.d/ \
    && . /home/guild/.nix-profile/etc/profile.d/nix.sh \
    && sudo crontab -u guild /etc/cron.d/crontab

# INSTALL DEPS  
RUN /nix/var/nix/profiles/per-user/guild/profile/bin/nix-env -i python3 systemd libsodium tmux jq ncurses libtool autoconf git wget gnupg column less openssl vim \
    && /nix/var/nix/profiles/per-user/guild/profile/bin/nix-channel --update \
    && /nix/var/nix/profiles/per-user/guild/profile/bin/nix-env -u --always \
    && /nix/var/nix/profiles/per-user/guild/profile/bin/nix-collect-garbage -d

# GUILD SKAffold
RUN sudo mkdir -p $CNODE_HOME/files $CNODE_HOME/db $CNODE_HOME/logs $CNODE_HOME/scripts $CNODE_HOME/sockets $CNODE_HOME/priv/files $CNODE_HOME/db/blocks /home/guild/.scripts
# ENTRY SCRIPT
ADD https://hydra.iohk.io/build/3670619/download/1/mainnet-shelley-genesis.json $CNODE_HOME/priv/files/
ADD https://hydra.iohk.io/build/3670619/download/1/mainnet-byron-genesis.json $CNODE_HOME/priv/files/
ADD https://hydra.iohk.io/build/3670619/download/1/mainnet-config.json $CNODE_HOME/priv/files/
ADD https://hydra.iohk.io/build/3670619/download/1/mainnet-topology.json $CNODE_HOME/priv/files/
ADD https://raw.githubusercontent.com/stakelovelace/cardano-node/master/master-topology.sh  /home/guild/.scripts/
ADD https://raw.githubusercontent.com/stakelovelace/cardano-node/master/ip2loc.sh  /home/guild/.scripts/
ADD https://raw.githubusercontent.com/stakelovelace/cardano-node/master/guild-topology.sh  /home/guild/.scripts/
ADD https://raw.githubusercontent.com/stakelovelace/cardano-node/master/block_watcher.sh  /home/guild/.scripts/
ADD https://raw.githubusercontent.com/stakelovelace/cardano-node/master/entrypoint.sh  /home/guild/
RUN sudo chown -R guild:guild  /home/guild/.scripts/*.sh \
    && sudo chown -R guild:guild $CNODE_HOME/* \
    && sudo chown -R guild:guild /home/guild/.* 

# GUILD SCRIPTS
RUN cd && git clone --quiet https://github.com/cardano-community/guild-operators.git \
    && cp -rf ~/guild-operators/scripts/cnode-helper-scripts/* $CNODE_HOME/scripts \
    && cp -rf ~/guild-operators/scripts/* $CNODE_HOME/scripts \
    && cp -rf ~/guild-operators/files/* $CNODE_HOME/files \
    && rm -rf ~/guild-operators \
    && rm /opt/cardano/cnode/files/byron-genesis.json  && rm /opt/cardano/cnode/files/genesis.json && if [ -f /opt/cardano/cnode/files/config.json ]; then rm /opt/cardano/cnode/files/config.json; else echo NO; fi \
    && ln -s /opt/cardano/cnode/priv/files/mainnet-byron-genesis.json /opt/cardano/cnode/files/byron-genesis.json \
    && ln -s /opt/cardano/cnode/priv/files/mainnet-config.json /opt/cardano/cnode/files/config.json \
    && ln -s /opt/cardano/cnode/priv/files/mainnet-shelley-genesis.json /opt/cardano/cnode/files/genesis.json \
    && sudo chmod a+x  /home/guild/.scripts/*.sh $CNODE_HOME/scripts/*.sh

RUN sudo apt-get -y remove exim4 && sudo apt-get -y purge && sudo apt-get -y clean && sudo apt-get -y autoremove && sudo rm -rf /var/lib/apt/lists/* # && sudo rm -rf /usr/bin/apt* && sudo rm /nix/var/nix/profiles/per-user/guild/profile/bin/nix-* 

ENTRYPOINT ["./entrypoint.sh"]
