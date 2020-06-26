#!/bin/bash

downloadPage=https://www.minecraft.net/en-us/download/server/bedrock/

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
  1.12)
    VERSION=1.12.0.28
    ;;
  1.13|PREVIOUS)
    VERSION=1.13.0.34
    ;;
  1.14)
    VERSION=1.14.60.5
    ;;
  1.16)
    VERSION=1.16.0.2
    ;;
  *)
    for a in data-bi-prtid data-platform; do
      DOWNLOAD_URL=$(restify --attribute=${a}=serverBedrockLinux ${downloadPage} 2> /tmp/restify.out | jq -r '.[0].href' || echo '')
      if [[ ${DOWNLOAD_URL} ]]; then
        break
      fi
    done
    if [[ ${DOWNLOAD_URL} =~ http.*/.*-(.*)\.zip ]]; then
      VERSION=${BASH_REMATCH[1]}
    else
      echo "Failed to extract download URL '${DOWNLOAD_URL}' from ${downloadPage}"
      cat /tmp/restify.out
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

  # remove only binaries and some docs, to allow for an upgrade of those
  rm -rf bedrock_server *.so release-notes.txt bedrock_server_how_to.html valid_known_packs.json premium_cache 2> /dev/null

  bkupDir=backup-pre-${VERSION}
  for d in behavior_packs definitions minecraftpe resource_packs structures treatments world_templates
  do
    if [ -d $d ]; then
      mkdir -p $bkupDir
      echo "Backing up $d into $bkupDir"
      mv $d $bkupDir
    fi
  done

  # ... overwrite all game files, except config files
  unzip -q ${TMP_ZIP} -x server.properties whitelist.json permissions.json
  rm ${TMP_ZIP}

  chmod +x bedrock_server
  mv bedrock_server bedrock_server-${VERSION}
fi

set-property --file server.properties --bulk /etc/bds-property-definitions.json

export LD_LIBRARY_PATH=.

echo "Starting Bedrock server..."
exec ./bedrock_server-${VERSION}
