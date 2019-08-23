FROM debian

ARG ARCH=amd64

RUN apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y \
    curl \
    unzip \
    && apt-get clean

EXPOSE 19132/udp

VOLUME ["/data"]

WORKDIR /data

ENTRYPOINT ["/usr/local/bin/entrypoint-demoter", "--match", "/data", "--debug", "--stdin-on-term", "stop", "/opt/bedrock-entry.sh"]

ARG DEMOTER_VERSION=0.2.0
ADD https://github.com/itzg/entrypoint-demoter/releases/download/${DEMOTER_VERSION}/entrypoint-demoter_${DEMOTER_VERSION}_Linux_${ARCH}.tar.gz /tmp/
RUN cd /usr/local/bin ; tar xvf /tmp/entrypoint-demoter_${DEMOTER_VERSION}_Linux_${ARCH}.tar.gz entrypoint-demoter && \
  rm /tmp/entrypoint-demoter_${DEMOTER_VERSION}_Linux_${ARCH}.tar.gz

ARG SET_PROPERTY_VERSION=0.1.1
ADD https://github.com/itzg/set-property/releases/download/${SET_PROPERTY_VERSION}/set-property_${SET_PROPERTY_VERSION}_linux_${ARCH}.tar.gz /tmp/
RUN cd /usr/local/bin ; tar xvf /tmp/set-property_${SET_PROPERTY_VERSION}_linux_${ARCH}.tar.gz set-property && \
  rm /tmp/set-property_${SET_PROPERTY_VERSION}_linux_${ARCH}.tar.gz

COPY *.sh /opt/

COPY property-definitions.json /etc/bds-property-definitions.json

# Available versions listed at
# https://minecraft.gamepedia.com/Bedrock_Edition_1.11.0
# https://minecraft.gamepedia.com/Bedrock_Edition_1.12.0
ENV VERSION=1.12
