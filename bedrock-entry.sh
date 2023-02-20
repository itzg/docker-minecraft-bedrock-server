#!/bin/bash

set -eo pipefail

: "${TMP_DIR:=/tmp}"
: "${PREVIEW:=false}"

function isTrue() {
  case "${1,,}" in
  true | on | 1)
    return 0
    ;;
  *)
    return 1
    ;;
  esac
}

function lookupVersion() {
  platform=${1:?Missing required platform indicator}

  for i in {1..3}; do
    DOWNLOAD_URL=$(restify --user-agent=itzg/minecraft-bedrock-server --headers "accept-language:*" --attribute=data-platform="${platform}" "${downloadPage}" 2> restify.err | jq -r '.[0].href' || echo '')
    if [[ ${DOWNLOAD_URL} ]]; then
      break 2
    fi
    sleep 1
  done
  if [[ -z ${DOWNLOAD_URL} ]]; then
    DOWNLOAD_URL=$(curl -s https://mc-bds-helper.vercel.app/api/latest)
  fi

  if [[ ${DOWNLOAD_URL} =~ http.*/.*-(.*)\.zip ]]; then
    VERSION=${BASH_REMATCH[1]}
  elif [[ $(ls -rv bedrock_server-* 2> /dev/null|head -1) =~ bedrock_server-(.*) ]]; then
    VERSION=${BASH_REMATCH[1]}
    echo "WARN Minecraft download page failed, so using existing download of $VERSION"
    cat restify.err
  else
    if [[ -f restify.err ]]; then
      echo "Failed to extract download URL '${DOWNLOAD_URL}' from ${downloadPage}"
      cat restify.err
      rm restify.err
    else
      echo "Failed to lookup download URL: ${DOWNLOAD_URL}"
    fi
    exit 2
  fi
  rm -f restify.err
}

if [[ ${DEBUG^^} = TRUE ]]; then
  set -x
  curlArgs=(-v)
  echo "DEBUG: running as $(id -a) with $(ls -ld /data)"
  echo "       current directory is $(pwd)"
fi

downloadPage=https://www.minecraft.net/en-us/download/server/bedrock

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
  1.12)
    VERSION=1.12.0.28
    ;;
  1.13)
    VERSION=1.13.0.34
    ;;
  1.14)
    VERSION=1.14.60.5
    ;;
  1.16)
    VERSION=1.16.20.03
    ;;
  1.17)
    VERSION=1.17.41.01
    ;;
  1.17.41)
    VERSION=1.17.41.01
    ;;
  1.18|PREVIOUS)
    VERSION=1.18.33.02
    ;;
  PREVIEW)
    echo "Looking up latest preview version..."
    lookupVersion serverBedrockPreviewLinux
    ;;
  LATEST)
    echo "Looking up latest version..."
    lookupVersion serverBedrockLinux
    ;;
  *)
    # use the given version exactly
    ;;
esac

if [ ! -f "bedrock_server-${VERSION}" ]; then

  if [[ ! ${DOWNLOAD_URL} ]]; then
    binPath=bin-linux
    if isTrue "${PREVIEW}"; then
      binPath=bin-linux-preview
    fi
    DOWNLOAD_URL="https://minecraft.azureedge.net/${binPath}/bedrock-server-${VERSION}.zip"
  fi

  [[ $TMP_DIR != /tmp ]] && mkdir -p "$TMP_DIR"
  TMP_ZIP="$TMP_DIR/$(basename "${DOWNLOAD_URL}")"

  echo "Downloading Bedrock server version ${VERSION} ..."
  if ! curl "${curlArgs[@]}" -o "${TMP_ZIP}" -fsSL ${DOWNLOAD_URL}; then
    echo "ERROR failed to download from ${DOWNLOAD_URL}"
    echo "      Double check that the given VERSION is valid"
    exit 2
  fi

  # remove only binaries and some docs, to allow for an upgrade of those
  rm -rf bedrock_server bedrock_server-* *.so release-notes.txt bedrock_server_how_to.html valid_known_packs.json premium_cache 2> /dev/null

  bkupDir=backup-pre-${VERSION}
  # fixup any previous interrupted upgrades
  rm -rf "${bkupDir}"
  for d in behavior_packs definitions minecraftpe resource_packs structures treatments world_templates
  do
    if [ -d $d ]; then
      mkdir -p $bkupDir
      echo "Backing up $d into $bkupDir"
      mv $d $bkupDir
    fi
  done

  # remove old package backups, but keep PACKAGE_BACKUP_KEEP
  if (( ${PACKAGE_BACKUP_KEEP:=2} >= 0 )); then
    shopt -s nullglob
    for d in $( ls -td1 backup-pre-* | tail +$(( PACKAGE_BACKUP_KEEP + 1 )) ); do
      echo "Pruning $d"
      rm -rf $d
    done
  fi

  # Do not overwrite existing files, which means the cleanup above needs to account for things
  # that MUST be replaced on upgrade
  unzip -q -n ${TMP_ZIP}
  [[ $TMP_DIR != /tmp ]] && rm -rf "$TMP_DIR"

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

allowListUsers=${ALLOW_LIST_USERS:-${WHITE_LIST_USERS}}

if [ -n "$allowListUsers" ]; then
  echo "Setting allow list"
  for f in whitelist.json allowlist.json; do
    if [ -f $f ]; then
      rm -rf $f
    fi
    jq -n --arg users "$allowListUsers" '$users | split(",") | map({"name": .})' > $f
  done
  # activate server property to enable list usage
  export WHITE_LIST=true
  export ALLOW_LIST=true
fi

set-property --file server.properties --bulk /etc/bds-property-definitions.json

export LD_LIBRARY_PATH=.

echo "Starting Bedrock server..."
if [ -f /usr/local/bin/box64 ] ; then
    exec box64 ./bedrock_server-${VERSION}
else
    exec ./bedrock_server-${VERSION}
fi
