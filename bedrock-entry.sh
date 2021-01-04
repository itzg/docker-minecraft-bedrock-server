#!/bin/bash

set -eo pipefail

if [[ ${DEBUG^^} = TRUE ]]; then
  set -x
  curlArgs=(-v)
fi

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

case ${VERSION^^} in
  1.11)
    VERSION=1.11.4.2
    ;;
  1.12)
    VERSION=1.12.0.28
    ;;
  1.13)
    VERSION=1.13.0.34
    ;;
  1.14|PREVIOUS)
    VERSION=1.14.60.5
    ;;
  1.16.1)
    VERSION=1.16.1.02
    ;;
  1.16)
    VERSION=1.16.20.03
    ;;
  LATEST)
    for a in data-bi-prtid data-platform; do
      for i in {1..3}; do
        DOWNLOAD_URL=$(restify --attribute=${a}=serverBedrockLinux ${downloadPage} 2> restify.err | jq -r '.[0].href' || echo '')
        if [[ ${DOWNLOAD_URL} ]]; then
          break 2
        fi
      done
    done
    if [[ ${DOWNLOAD_URL} =~ http.*/.*-(.*)\.zip ]]; then
      VERSION=${BASH_REMATCH[1]}
    elif [[ $(ls -rv bedrock_server-* 2> /dev/null|head -1) =~ bedrock_server-(.*) ]]; then
      VERSION=${BASH_REMATCH[1]}
      echo "WARN Minecraft download page failed, so using existing download of $VERSION"
      cat restify.err
    else
      echo "Failed to extract download URL '${DOWNLOAD_URL}' from ${downloadPage}"
      cat restify.err
      rm restify.err
      exit 2
    fi
    rm restify.err
    ;;
  *)
    # use the given version exactly
    ;;
esac

if [ ! -f "bedrock_server-${VERSION}" ]; then

  if [[ ! ${DOWNLOAD_URL} ]]; then
    DOWNLOAD_URL=https://minecraft.azureedge.net/bin-linux/bedrock-server-${VERSION}.zip
  fi

  TMP_ZIP=/tmp/$(basename "${DOWNLOAD_URL}")

  echo "Downloading Bedrock server version ${VERSION} ..."
  if ! curl "${curlArgs[@]}" -o ${TMP_ZIP} -fsSL ${DOWNLOAD_URL}; then
    echo "ERROR failed to download from ${DOWNLOAD_URL}"
    echo "      Double check that the given VERSION is valid"
    exit 2
  fi

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
  unzip -q ${TMP_ZIP} -x $(ls server.properties whitelist.json permissions.json 2> /dev/null)
  rm ${TMP_ZIP}

  chmod +x bedrock_server
  mv bedrock_server bedrock_server-${VERSION}
fi

if [ -n "$OPS" ] || [ -n "$MEMBERS" ] || [ -n "$VISITORS" ]; then
  echo "Updating permissions"
  jq -n --arg ops "$OPS" --arg members "$MEMBERS" --arg visitors "$VISITORS" '[
  [$ops      | split(",") | map({permission: "operator", xuid:.})],
  [$members  | split(",") | map({permission: "member", xuid:.})],
  [$visitors | split(",") | map({permission: "visitor", xuid:.})]
  ]| flatten' > permissions.json
fi

if [ -n "$WHITE_LIST_USERS" ]; then
  echo "Setting whitelist"
  rm -rf whitelist.json
  jq -n --arg users "$WHITE_LIST_USERS" '$users | split(",") | map({"name": .})' > whitelist.json
  # flag whitelist to true so the server properties process correctly
  export WHITE_LIST=true
fi

set-property --file server.properties --bulk /etc/bds-property-definitions.json

export LD_LIBRARY_PATH=.

echo "Starting Bedrock server..."
exec ./bedrock_server-${VERSION}
