FROM debian

ARG ARCH=amd64

RUN apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y \
    curl \
    unzip \
    jq \
    && apt-get clean

EXPOSE 19132/udp

VOLUME ["/data"]

WORKDIR /data

ENTRYPOINT ["/usr/local/bin/entrypoint-demoter", "--match", "/data", "--debug", "--stdin-on-term", "stop", "/opt/bedrock-entry.sh"]

ARG EASY_ADD_VERSION=0.2.0
ADD https://github.com/itzg/easy-add/releases/download/${EASY_ADD_VERSION}/easy-add_${EASY_ADD_VERSION}_linux_${ARCH} /usr/local/bin/easy-add
RUN chmod +x /usr/local/bin/easy-add

ARG DEMOTER_VERSION=0.2.1
RUN easy-add --file entrypoint-demoter --from https://github.com/itzg/entrypoint-demoter/releases/download/${DEMOTER_VERSION}/entrypoint-demoter_${DEMOTER_VERSION}_Linux_${ARCH}.tar.gz

ARG SET_PROPERTY_VERSION=0.1.1
RUN easy-add --file set-property --from https://github.com/itzg/set-property/releases/download/${SET_PROPERTY_VERSION}/set-property_${SET_PROPERTY_VERSION}_linux_${ARCH}.tar.gz

ARG RESTIFY_VERSION=1.2.0
RUN easy-add --file restify --from https://github.com/itzg/restify/releases/download/${RESTIFY_VERSION}/restify_${RESTIFY_VERSION}_linux_amd64.tar.gz

COPY *.sh /opt/

COPY property-definitions.json /etc/bds-property-definitions.json

# Available versions listed at
# https://minecraft.gamepedia.com/Bedrock_Edition_1.11.0
# https://minecraft.gamepedia.com/Bedrock_Edition_1.12.0
# https://minecraft.gamepedia.com/Bedrock_Edition_1.13.0
# https://minecraft.gamepedia.com/Bedrock_Edition_1.14.0
ENV VERSION=LATEST
