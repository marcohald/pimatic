FROM resin/armv7hf-debian-qemu
ENV DEBIAN_FRONTEND noninteractive

RUN [ "cross-build-start" ]

RUN apt-get update && \
    apt-get install -yq \
            apt-transport-https \
            curl \
            git \
            wget
            
RUN curl -s https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - && \
    echo 'deb https://deb.nodesource.com/node_4.x jessie main' > /etc/apt/sources.list.d/nodesource.list && \
    echo 'deb-src https://deb.nodesource.com/node_4.x jessie main' >> /etc/apt/sources.list.d/nodesource.list && \
    apt-get update && \
    apt-get install -yq \
            nodejs

# Install sqlite3 to prevent npm from compiling it
RUN apt-get update && apt-get install -y apt-utils && apt-get install -y sqlite3 && npm install sqlite3 --sqlite=/usr/local

RUN mkdir /home/pimatic-app && cd /home && npm install pimatic --prefix pimatic-app --production && ls

RUN cd /home/pimatic-app/node_modules/pimatic && npm link \
	&& cp /home/pimatic-app/node_modules/pimatic/config_default.json /home/pimatic-app/config.json

# Set the password
RUN sed -i "s/\"password\": \"\"/\"password\": \"pimatic\"/g" /home/pimatic-app/config.json

# Run pimatic once so that all coffeescripts are built and npm packages are downloaded and built
## Make sure that pimatic will exit when startup is completed
RUN cp /home/pimatic-app/node_modules/pimatic/startup.coffee /home/pimatic-app/node_modules/pimatic/startup.backup
RUN sed -i "s/initComplete = true/framework.destroy().then( -> exit(0) )/g" /home/pimatic-app/node_modules/pimatic/startup.coffee
## Run pimatic
RUN cd / && pimatic.js
## Restore startup.coffee and remove it from compiled cache
RUN rm /home/pimatic-app/node_modules/pimatic/startup.coffee \
	&& mv /home/pimatic-app/node_modules/pimatic/startup.backup /home/pimatic-app/node_modules/pimatic/startup.coffee \
	&& rm /home/pimatic-app/node_modules/pimatic/.js/startup.*



RUN [ "cross-build-end" ] 
# The node Dockerfile sets the entrypoint to "node". We need this to be bash in order to use pimatic.
ENTRYPOINT ["/bin/bash"]

# Expose port 80
EXPOSE 80
