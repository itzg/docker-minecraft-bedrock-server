FROM debian

# hook into docker BuildKit --platform support
# see https://docs.docker.com/engine/reference/builder/#automatic-platform-args-in-the-global-scope
ARG TARGETOS
ARG TARGETARCH
ARG TARGETVARIANT

RUN --mount=target=/build,source=build /build/install-packages

ARG BOX64_PACKAGE=box64
RUN --mount=target=/build,source=build BOX64_PACKAGE=$BOX64_PACKAGE /build/setup-arm64

EXPOSE 19132/udp

VOLUME ["/data"]

WORKDIR /data

ENTRYPOINT ["/usr/local/bin/entrypoint-demoter", "--match", "/data", "--debug", "--stdin-on-term", "stop", "/opt/bedrock-entry.sh"]

ARG APPS_REV=1
ARG GITHUB_BASEURL=https://github.com

ARG EASY_ADD_VERSION=0.8.8
ADD ${GITHUB_BASEURL}/itzg/easy-add/releases/download/${EASY_ADD_VERSION}/easy-add_${TARGETOS}_${TARGETARCH}${TARGETVARIANT} /usr/bin/easy-add
RUN chmod +x /usr/bin/easy-add

ARG ENTRYPOINT_DEMOTER_VERSION=0.4.6
RUN easy-add --var version=${ENTRYPOINT_DEMOTER_VERSION} --var app=entrypoint-demoter --file {{.app}} --from ${GITHUB_BASEURL}/itzg/{{.app}}/releases/download/v{{.version}}/{{.app}}_{{.version}}_linux_${TARGETARCH}.tar.gz

ARG SET_PROPERTY_VERSION=0.1.2
RUN easy-add --var version=${SET_PROPERTY_VERSION} --var app=set-property --file {{.app}} --from ${GITHUB_BASEURL}/itzg/{{.app}}/releases/download/{{.version}}/{{.app}}_{{.version}}_linux_${TARGETARCH}.tar.gz

ARG RESTIFY_VERSION=1.7.5
RUN easy-add --var os=${TARGETOS} --var arch=${TARGETARCH}${TARGETVARIANT} \
  --var version=${RESTIFY_VERSION} --var app=restify --file {{.app}} \
  --from ${GITHUB_BASEURL}/itzg/{{.app}}/releases/download/{{.version}}/{{.app}}_{{.version}}_{{.os}}_{{.arch}}.tar.gz

ARG MC_MONITOR_VERSION=0.15.0
RUN easy-add --var os=${TARGETOS} --var arch=${TARGETARCH}${TARGETVARIANT} \
  --var version=${MC_MONITOR_VERSION} --var app=mc-monitor --file {{.app}} \
  --from ${GITHUB_BASEURL}/itzg/{{.app}}/releases/download/{{.version}}/{{.app}}_{{.version}}_{{.os}}_{{.arch}}.tar.gz

ARG MC_SERVER_RUNNER_VERSION=1.12.3
RUN easy-add --var os=${TARGETOS} --var arch=${TARGETARCH}${TARGETVARIANT} \
  --var version=${MC_SERVER_RUNNER_VERSION} --var app=mc-server-runner --file {{.app}} \
  --from ${GITHUB_BASEURL}/itzg/{{.app}}/releases/download/{{.version}}/{{.app}}_{{.version}}_{{.os}}_{{.arch}}.tar.gz

COPY *.sh /opt/

COPY property-definitions.json /etc/bds-property-definitions.json
COPY bin/* /usr/local/bin/

# Available versions listed at
# https://minecraft.wiki/w/Bedrock_Edition_1.11.0
# https://minecraft.wiki/w/Bedrock_Edition_1.12.0
# https://minecraft.wiki/w/Bedrock_Edition_1.13.0
# https://minecraft.wiki/w/Bedrock_Edition_1.14.0
ENV VERSION=LATEST \
    SERVER_PORT=19132

HEALTHCHECK --start-period=1m CMD /usr/local/bin/mc-monitor status-bedrock --host 127.0.0.1 --port $SERVER_PORT
