FROM debian

RUN apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -y \
    curl \
    unzip \
    && apt-get clean

RUN useradd --home-dir /data --create-home -u 1000 minecraft

ENTRYPOINT ["/opt/bedrock-entry.sh"]

EXPOSE 19132/udp 41587

COPY *.sh /opt/

VOLUME ["/data"]

WORKDIR /data

USER minecraft

# Available versions listed at
# https://minecraft.gamepedia.com/Bedrock_Edition_1.11.0
# https://minecraft.gamepedia.com/Bedrock_Edition_1.12.0
ENV VERSION=1.11
