#!/bin/bash

if [[ ${EULA^^} != TRUE ]]; then
  echo
  echo "EULA must be set to TRUE to indicate agreement with the Minecraft End User License"
  echo "See https://minecraft.net/terms"
  echo
  exit 1
fi

set -e

case ${VERSION} in
  1.11)
    VERSION=1.11.4.2
    ;;
  1.12)
    VERSION=1.12.0.28
    ;;
esac

if [ ! -f bedrock_server-${VERSION} ]; then

  DOWNLOAD_URL=https://minecraft.azureedge.net/bin-linux/bedrock-server-${VERSION}.zip

  TMP_ZIP=/tmp/$(basename ${DOWNLOAD_URL})

  echo "Downloading Bedrock server ${VERSION} ..."
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