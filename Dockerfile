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

ARG EASY_ADD_VERSION=0.5.0
ADD https://github.com/itzg/easy-add/releases/download/${EASY_ADD_VERSION}/easy-add_${EASY_ADD_VERSION}_linux_${ARCH} /usr/local/bin/easy-add
RUN chmod +x /usr/local/bin/easy-add

RUN easy-add --var version=0.2.1 --var app=entrypoint-demoter --file entrypoint-demoter --from https://github.com/itzg/{{.app}}/releases/download/{{.version}}/{{.app}}_{{.version}}_Linux_{{.arch}}.tar.gz

RUN easy-add --var version=0.1.1 --var app=set-property --file set-property --from https://github.com/itzg/{{.app}}/releases/download/{{.version}}/{{.app}}_{{.version}}_{{.os}}_{{.arch}}.tar.gz

ARG RESTIFY_VERSION=1.2.0
RUN easy-add --var version=1.2.0 --var app=restify --file restify --from https://github.com/itzg/{{.app}}/releases/download/{{.version}}/{{.app}}_{{.version}}_{{.os}}_{{.arch}}.tar.gz

COPY *.sh /opt/

COPY property-definitions.json /etc/bds-property-definitions.json

# Available versions listed at
# https://minecraft.gamepedia.com/Bedrock_Edition_1.11.0
# https://minecraft.gamepedia.com/Bedrock_Edition_1.12.0
# https://minecraft.gamepedia.com/Bedrock_Edition_1.13.0
# https://minecraft.gamepedia.com/Bedrock_Edition_1.14.0
ENV VERSION=LATEST
