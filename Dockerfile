FROM debian

RUN apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y \
    curl \
    unzip \
    && apt-get clean

ARG DEMOTER_VERSION=0.1.0
ARG DEMOTER_ARCH=amd64

ADD https://github.com/itzg/entrypoint-demoter/releases/download/${DEMOTER_VERSION}/entrypoint-demoter_${DEMOTER_VERSION}_linux_${DEMOTER_ARCH}.deb /usr/src

RUN dpkg -i /usr/src/entrypoint-demoter_${DEMOTER_VERSION}_linux_${DEMOTER_ARCH}.deb

ENTRYPOINT ["/usr/local/bin/entrypoint-demoter", "--match", "/data", "--debug", "/opt/bedrock-entry.sh"]

EXPOSE 19132/udp

COPY *.sh /opt/

VOLUME ["/data"]

WORKDIR /data

# Available versions listed at
# https://minecraft.gamepedia.com/Bedrock_Edition_1.11.0
# https://minecraft.gamepedia.com/Bedrock_Edition_1.12.0
ENV VERSION=1.11
