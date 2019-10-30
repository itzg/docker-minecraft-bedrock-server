#!/bin/bash

if [[ ${EULA^^} != TRUE ]]; then
  echo
  echo "EULA must be set to TRUE to indicate agreement with the Minecraft End User License"
  echo "See https://minecraft.net/terms"
  echo
  echo "Current value is '${EULA}'"
  echo
  exit 1
fi

set -e

case ${VERSION} in
  1.11)
    VERSION=1.11.4.2
    ;;
  1.12|PREVIOUS)
    VERSION=1.12.0.28
    ;;
  1.13)
    VERSION=1.13.0.34
    ;;
  *)
    DOWNLOAD_URL=$(restify --attribute=data-platform=serverBedrockLinux https://www.minecraft.net/en-us/download/server/bedrock/ | jq -r '.[0].href')
    if [[ ${DOWNLOAD_URL} =~ http.*/.*-(.*)\.zip ]]; then
      VERSION=${BASH_REMATCH[1]}
    else
      echo "Failed to process download URL ${DOWNLOAD_URL}"
      exit 2
    fi
    ;;
esac

if [ ! -f "bedrock_server-${VERSION}" ]; then

  if [[ ! ${DOWNLOAD_URL} ]]; then
    DOWNLOAD_URL=https://minecraft.azureedge.net/bin-linux/bedrock-server-${VERSION}.zip
  fi

  TMP_ZIP=/tmp/$(basename "${DOWNLOAD_URL}")

  echo "Downloading Bedrock server version ${VERSION} ..."
  curl -o ${TMP_ZIP} -fsSL ${DOWNLOAD_URL}

  # remove only binaries to allow for an upgrade of those
  rm -f bedrock_server *.so 2> /dev/null
  # ... use -n to avoid overwriting any existing files with the archive's copy
  unzip -n -q ${TMP_ZIP}
  rm ${TMP_ZIP}

  chmod +x bedrock_server
  mv bedrock_server bedrock_server-${VERSION}
fi

set-property --file server.properties --bulk /etc/bds-property-definitions.json

export LD_LIBRARY_PATH=.

echo "Starting Bedrock server..."
exec ./bedrock_server-${VERSION}