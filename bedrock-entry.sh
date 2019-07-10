#!/bin/bash

if [[ ${EULA^^} != TRUE ]]; then
  echo
  echo "EULA must be set to TRUE to indicate agreement with the Minecraft End User License"
  echo "See https://minecraft.net/terms"
  echo
  exit 1
fi

set -e

if [ ! -f bedrock_server ]; then

  case ${VERSION} in
    1.11)
      VERSION=1.11.4.2
      ;;
    1.12)
      VERSION=1.12.0.28
      ;;
  esac

  DOWNLOAD_URL=https://minecraft.azureedge.net/bin-linux/bedrock-server-${VERSION}.zip

  TMP_ZIP=/tmp/$(basename ${DOWNLOAD_URL})

  echo "Downloading Bedrock server ${VERSION} ..."
  curl -o ${TMP_ZIP} -fsSL ${DOWNLOAD_URL}
  unzip -q ${TMP_ZIP}
  chmod +x bedrock_server
fi

export LD_LIBRARY_PATH=.

echo "Starting Bedrock server..."
exec ./bedrock_server