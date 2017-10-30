FROM resin/armv7hf-debian-qemu
ENV DEBIAN_FRONTEND noninteractive

RUN [ "cross-build-start" ]

RUN apt-get update && \
    apt-get install -yq \
            apt-transport-https \
            curl \
            git \
            wget
            
RUN curl -s https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add -
RUN echo 'deb https://deb.nodesource.com/node_4.x jessie main' > /etc/apt/sources.list.d/nodesource.list
RUN echo 'deb-src https://deb.nodesource.com/node_4.x jessie main' >> /etc/apt/sources.list.d/nodesource.list
RUN apt-get update && \
    apt-get install -yq \
            nodejs


# Install Pimatic Following the Instructions at Pimatic Docs
# Ref: https://pimatic.org/guide/getting-started/installation/
RUN mkdir /home/pimatic-app
RUN /usr/bin/env node --version
RUN cd /home && npm install pimatic --prefix pimatic-app --production && ls

RUN cd /home/pimatic-app/node_modules/pimatic && npm link
RUN cp /home/pimatic-app/node_modules/pimatic/config_default.json /home/pimatic-app/config.json

RUN wget https://raw.githubusercontent.com/pimatic/pimatic/v0.9.x/install/pimatic-init-d && cp pimatic-init-d /etc/init.d/pimatic
RUN chmod +x /etc/init.d/pimatic
RUN chown root:root /etc/init.d/pimatic
RUN update-rc.d pimatic defaults
RUN sed -i "s/\"password\": \"\"/\"password\": \"pimatic\"/g" /home/pimatic-app/config.json

RUN [ "cross-build-end" ] 
# The node Dockerfile sets the entrypoint to "node". We need this to be bash in order to use pimatic.
ENTRYPOINT ["/bin/bash"]

# Expose port 80
EXPOSE 80
