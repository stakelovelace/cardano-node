# FROM https://hydra.iohk.io/job/Cardano/cardano-node/cardano-node-linux/latest-finished
# Latest Genesis: https://hydra.iohk.io/job/Cardano/cardano-node/cardano-deployment/latest-finished

FROM debian

ARG DEBIAN_FRONTEND=noninteractive

# Install locales package
RUN  apt-get update && apt-get install --no-install-recommends -y locales

# Uncomment en_US.UTF-8 for inclusion in generation
RUN sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen \
    && locale-gen \
    && echo "export LC_ALL=en_US.UTF-8" >> ~/.bashrc \
    && echo "export LANG=en_US.UTF-8" >> ~/.bashrc \
    && echo "export LANGUAGE=en_US.UTF-8" >> ~/.bashrc. 

ENV \
    ENV=/etc/profile \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    USER=guild \
    CNODE_HOME=/opt/cardano/cnode \
    PATH=/nix/var/nix/profiles/per-user/guild/profile/bin:/nix/var/nix/profiles/per-user/guild/profile/sbin:/opt/cardano/cnode/scripts:/bin:/sbin:/usr/bin:/usr/sbin \
    GIT_SSL_CAINFO=/etc/ssl/certs/ca-certificates.crt \
    NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt \
    NIX_PATH=/nix/var/nix/profiles/per-user/guild/channels

# PREREQ + DEBUG --no-install-recommends
RUN apt-get update && apt-get install -y curl wget apt-utils xz-utils netbase sudo coreutils dnsutils net-tools procps cron tcptraceroute bc

ADD https://raw.githubusercontent.com/stakelovelace/cardano-node/master/promtail.yml /etc/ 
ADD https://raw.githubusercontent.com/stakelovelace/cardano-node/master/promtail /etc/init.d/
ADD https://raw.githubusercontent.com/stakelovelace/cardano-node/master/crontab /etc/cron.d/crontab
RUN chmod a+x /etc/init.d/promtail && chmod 0600 /etc/cron.d/crontab && touch /var/log/cron.log 

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

# SETUP USER
RUN adduser --disabled-password --gecos '' guild
RUN adduser guild sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
RUN echo 'APT::Install-Recommends "false";' >> /etc/apt/apt.conf.d/00DisableInstallRecommends \
&&  echo 'APT::AutoRemove::RecommendsImportant "false";' >> /etc/apt/apt.conf.d/00DisableInstallRecommends \
&&  echo 'APT::AutoRemove::SuggestsImportant "false";' >> /etc/apt/apt.conf.d/00DisableInstallRecommends 

USER guild
WORKDIR /home/guild

# INSTALL NIX
RUN sudo curl -sL https://nixos.org/nix/install | sh \
    && sudo ln -s /nix/var/nix/profiles/per-user/etc/profile.d/nix.sh /etc/profile.d/ \
    && . /home/guild/.nix-profile/etc/profile.d/nix.sh \
    && sudo crontab -u guild /etc/cron.d/crontab

# INSTALL DEPS  
RUN /nix/var/nix/profiles/per-user/guild/profile/bin/nix-env -i python3 systemd libsodium tmux jq bc ncurses libtool autoconf git wget gnupg column less openssl vim \
    && /nix/var/nix/profiles/per-user/guild/profile/bin/nix-channel --update \
    && /nix/var/nix/profiles/per-user/guild/profile/bin/nix-env -u --always \
    && /nix/var/nix/profiles/per-user/guild/profile/bin/nix-collect-garbage -d

# GUILD SKAffold
RUN sudo mkdir -p $CNODE_HOME/files $CNODE_HOME/db $CNODE_HOME/logs $CNODE_HOME/scripts $CNODE_HOME/sockets $CNODE_HOME/priv \
    && sudo chown -R guild:guild $CNODE_HOME \
    && chmod -R 755 $CNODE_HOME 

# GUILD SCRIPTS
RUN cd && git clone --quiet https://github.com/cardano-community/guild-operators.git \
    && cp -rf ~/guild-operators/scripts/cnode-helper-scripts/* $CNODE_HOME/scripts \
    && cp -rf ~/guild-operators/scripts/* $CNODE_HOME/scripts \
    && cp -rf ~/guild-operators/files/* $CNODE_HOME/files \
    && rm -rf ~/guild-operators \
    && rm /opt/cardano/cnode/files/byron-genesis.json  && rm /opt/cardano/cnode/files/genesis.json && if [[ -f /opt/cardano/cnode/files/config.json ]]; then rm /opt/cardano/cnode/files/config.json; else echo NO; fi \
    && ln -s /opt/cardano/cnode/priv/files/mainnet-byron-genesis.json /opt/cardano/cnode/files/byron-genesis.json \
    && ln -s /opt/cardano/cnode/priv/files/mainnet-config.json /opt/cardano/cnode/files/config.json \
    && ln -s /opt/cardano/cnode/priv/files/mainnet-shelley-genesis.json /opt/cardano/cnode/files/genesis.json

# HYDRA BINS
RUN cd /usr/bin \
    && REDIRECT=$(curl -s https://hydra.iohk.io/job/Cardano/cardano-node/cardano-node-linux/latest-finished | grep "hydra.iohk.io/build" | cut -d "\"" -f 2) \
    && DOWNLATEST=$(curl -s $REDIRECT | grep "tar.gz" | head -n 1 |  cut -d "\"" -f 2) \
    && sudo curl -o cardano-node-latest-linux.tar.gz $DOWNLATEST \
    && sudo tar xzvf cardano-node-latest-linux.tar.gz \
    && sudo rm cardano-node-latest-linux.tar.gz \
    && sudo mv configuration $CNODE_HOME/files

# ENTRY SCRIPT
ADD https://raw.githubusercontent.com/stakelovelace/cardano-node/master/master-topology.sh ./
ADD https://raw.githubusercontent.com/stakelovelace/cardano-node/master/guild-topology.sh ./
ADD https://raw.githubusercontent.com/stakelovelace/cardano-node/master/entrypoint.sh ./
RUN sudo chown -R guild:guild /home/guild/entrypoint.sh \
    && sudo chown -R guild:guild $CNODE_HOME/files/* \
    && sudo chmod a+x /home/guild/*.sh


RUN sudo apt-get -y remove exim4 && sudo apt-get -y purge && sudo apt-get -y autoremove #&& sudo rm -rf /usr/bin/apt*

# CMD /bin/bash
ENTRYPOINT ["./entrypoint.sh"]
