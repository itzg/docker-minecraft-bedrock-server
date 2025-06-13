#!/bin/bash

set -eo pipefail

: "${DOWNLOAD_DIR:=${PWD}/.downloads}"
: "${PREVIEW:=false}"

function isTrue() {
  [[ "${1,,}" =~ ^(true|on|1)$ ]] && return 0
  return 1
}

function replace_version_in_url() {
  local original_url="$1"
  local new_version="$2"

  # Use sed to replace the version number in the URL
  local modified_url
  modified_url=$(echo "$original_url" | sed -E "s/(bedrock-server-)[^/]+(\.zip)/\1${new_version}\2/")

  echo "$modified_url"
}

function lookupVersion() {
  platform=${1:?Missing required platform indicator}
  # TODO need to find out API call to lookup custom version
  # customVersion=${2:-}

  DOWNLOAD_URL=$(
    curl -fsSL "${getUrlPage}" |
      jq --arg platform serverBedrockLinux -rR '
        try(fromjson) catch({}) |
        .result.links // halt_error(1) |
          map(
            select(.downloadType == $platform)
          ) |
          if length > 0 then
            first |
            .downloadUrl
          else
            (
              "Error: could not find platform (\($platform))\n" |
              stderr |
              "" |
              halt_error(2)
            )
          end
        '
  )

  # shellcheck disable=SC2012
  if [[ ${DOWNLOAD_URL} =~ http.*/.*-(.*)\.zip ]]; then
    VERSION=${BASH_REMATCH[1]}
  elif [[ $(ls -rv bedrock_server-* 2> /dev/null|head -1) =~ bedrock_server-(.*) ]]; then
    VERSION=${BASH_REMATCH[1]}
    echo "WARN Minecraft download page failed, so using existing download of $VERSION"
  else
    echo "Failed to lookup download URL: ${DOWNLOAD_URL}"
    exit 2
  fi
}

if [[ ${DEBUG^^} == TRUE ]]; then
  set -x
  curlArgs=(-v)
  echo "DEBUG: running as $(id -a) with $(ls -ld /data)"
  echo "       current directory is $(pwd)"
fi

export HOME="${PWD}"

# Looks like both net and net-secondary hostnames work
getUrlPage=https://net-secondary.web.minecraft-services.net/api/v1.0/download/links

if [[ ${EULA^^} != TRUE ]]; then
  echo
  echo "EULA must be set to TRUE to indicate agreement with the Minecraft End User License"
  echo "See https://minecraft.net/terms"
  echo
  echo "Current value is '${EULA}'"
  echo
  exit 1
fi

# Check for DIRECT_DOWNLOAD_URL override first
if [[ -n "${DIRECT_DOWNLOAD_URL}" ]]; then
  echo "Using direct download URL from DIRECT_DOWNLOAD_URL environment variable."
  DOWNLOAD_URL="${DIRECT_DOWNLOAD_URL}"
  # If VERSION is not explicitly set, try to extract it from the URL
  if [[ -z "${VERSION}" ]]; then
    if [[ "${DOWNLOAD_URL}" =~ bedrock-server-([0-9\.]+)\.zip ]]; then
      VERSION=${BASH_REMATCH[1]}
      echo "Extracted VERSION=${VERSION} from DIRECT_DOWNLOAD_URL."
    else
      echo "WARNING: Could not extract VERSION from DIRECT_DOWNLOAD_URL. Please ensure VERSION environment variable is set."
      # Optionally exit here if VERSION is strictly required, but for testing, often the test will fail later.
    fi
  else
    echo "VERSION=${VERSION} is explicitly set, using it with DIRECT_DOWNLOAD_URL."
  fi
else # Original logic: if DIRECT_DOWNLOAD_URL is NOT set, proceed with lookup
  case ${VERSION^^} in
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
      if isTrue "$PREVIEW"; then
        echo "Using given preview version ${VERSION}"
        lookupVersion serverBedrockPreviewLinux "${VERSION}"
      else
        echo "Using given version ${VERSION}"
        lookupVersion serverBedrockLinux "${VERSION}"
      fi
      ;;
  esac
fi

if [[ ! -f "bedrock_server-${VERSION}" ]]; then

  [[ $DOWNLOAD_DIR != /tmp ]] && mkdir -p "$DOWNLOAD_DIR"
  TMP_ZIP="$DOWNLOAD_DIR/$(basename "${DOWNLOAD_URL}")"

  echo "Downloading Bedrock server version ${VERSION} ..."
  if ! curl "${curlArgs[@]}" -o "${TMP_ZIP}" -A "itzg/minecraft-bedrock-server" -fsSL "${DOWNLOAD_URL}"; then
    echo "ERROR failed to download from ${DOWNLOAD_URL}"
    echo "      Double check that the given VERSION is valid"
    exit 2
  fi

  # remove only binaries and some docs, to allow for an upgrade of those
  rm -rf -- bedrock_server bedrock_server-* *.so release-notes.txt bedrock_server_how_to.html valid_known_packs.json premium_cache 2> /dev/null

  bkupDir=backup-pre-${VERSION}
  # fixup any previous interrupted upgrades
  rm -rf "${bkupDir}"
  for d in behavior_packs definitions minecraftpe resource_packs structures treatments world_templates; do
    if [[ -d $d && -n "$(ls $d)" ]]; then
      mkdir -p "${bkupDir}/$d"
      echo "Backing up $d into $bkupDir"
      if [[ "$d" == "resource_packs" ]]; then
        # Copy over resource packs to ensure user-supplied ones remain
        cp -a $d/* "${bkupDir}/$d/"

        # ...however, need to fully remove Mojang provided resource packs to ensure consistent content
        for rp_dir in chemistry vanilla editor; do
          if [[ -d "$d/$rp_dir" ]]; then
            # shellcheck disable=SC2115
            rm -rf "$d/$rp_dir"
          fi
        done
      elif [[ "$d" == "behavior_packs" ]]; then
        # remove Mojang provided ones
        find behavior_packs \( -name 'vanilla*' -o -name 'chemistry*' -o -name 'experimental*' \) -exec rm -rf {} +
      else
        mv $d "${bkupDir}/"
      fi
    fi
  done

  # remove old package backups, but keep PACKAGE_BACKUP_KEEP
  if (( ${PACKAGE_BACKUP_KEEP:=2} >= 0 )); then
    shopt -s nullglob
    # shellcheck disable=SC2012
    for d in $( ls -td1 backup-pre-* | tail +$(( PACKAGE_BACKUP_KEEP + 1 )) ); do
      echo "Pruning backup directory: $d"
      rm -rf "$d"
    done
  fi

  # Do not overwrite existing files, which means the cleanup above needs to account for things
  # that MUST be replaced on upgrade
  unzip -q -n "${TMP_ZIP}"
  [[ $DOWNLOAD_DIR != /tmp ]] && rm -rf "$DOWNLOAD_DIR"

  chmod +x bedrock_server
  mv bedrock_server "bedrock_server-${VERSION}"
fi

if [[ -n "$OPS" || -n "$MEMBERS" || -n "$VISITORS" ]]; then
  echo "Updating permissions"
  jq -n --arg ops "$OPS" --arg members "$MEMBERS" --arg visitors "$VISITORS" '[
  [$ops      | split(",") | map({permission: "operator", xuid:.})],
  [$members  | split(",") | map({permission: "member", xuid:.})],
  [$visitors | split(",") | map({permission: "visitor", xuid:.})]
  ]| flatten' > permissions.json
fi

if [[ -n "$ALLOW_LIST_USERS" || -n "$WHITE_LIST_USERS" ]]; then
  allowListUsers=${ALLOW_LIST_USERS:-$WHITE_LIST_USERS}

  if [[ "$allowListUsers" ]]; then
    echo "Setting allow list"
    if [[ "$allowListUsers" != *":"* ]]; then
      jq -c -n --arg users "$allowListUsers" '$users | split(",") | map({"ignoresPlayerLimit":false,"name": .})' > "allowlist.json"
    else
      jq -c -n --arg users "$allowListUsers" '$users | split(",") | map(split(":") | {"ignoresPlayerLimit":false,"name": .[0], "xuid": .[1]})' > "allowlist.json"
    fi
    # activate server property to enable list usage
    ALLOW_LIST=true
  else
    ALLOW_LIST=false
    rm -f allowlist.json
  fi
fi

if [[ -n "$VARIABLES" ]]; then
  echo "Setting variables"
  mkdir -p config/default

  # Try to parse VARIABLES as JSON
  if echo "$VARIABLES" | jq empty >/dev/null 2>&1; then
    # VARIABLES is valid JSON
    echo "$VARIABLES" | jq '.' > "config/default/variables.json"
  else
    # VARIABLES is not valid JSON, attempt to parse as custom format
    echo "VARIABLES is not valid JSON, attempting to parse as custom format"

    # Parse the VARIABLES using custom format (key:value,key:value)
    # Note: Values should not contain unescaped commas or colons
    jq -n --arg vars "$VARIABLES" '
      $vars
      | split(",")
      | map(
          split("=") as $kv |
          { ($kv[0]): ($kv[1] | fromjson? // $kv[1]) }
        )
      | add
    ' > "config/default/variables.json"
  fi
fi



# prevent issue with bind mounted server.properties which can not be moved (sed tries to move the file when '-i' is used)
_SERVER_PROPERTIES=$(sed '/^white-list=.*/d' server.properties) #Removes white-list= line from server.properties
echo "${_SERVER_PROPERTIES}" > server.properties
export ALLOW_LIST

# update server.properties with environment settings
set-property --file server.properties --bulk /etc/bds-property-definitions.json

export LD_LIBRARY_PATH=.

mcServerRunnerArgs=()
if isTrue "${ENABLE_SSH}"; then
  mcServerRunnerArgs+=(--remote-console)
  if ! [[ -v RCON_PASSWORD ]]; then
    RCON_PASSWORD=$(openssl rand -hex 12)
    export RCON_PASSWORD
  fi

  # For ssh access by tools, export the current password.
  # Use rcon's format to align with Java, as Java uses the rcon password for SSH as well.
  echo "password=${RCON_PASSWORD}" > "$HOME/.remote-console.env"
  echo "password: \"${RCON_PASSWORD}\"" > "$HOME/.remote-console.yaml"
fi

echo "Starting Bedrock server..."
if [[ -f /usr/local/bin/box64 ]] ; then
    exec mc-server-runner "${mcServerRunnerArgs[@]}" box64 ./"bedrock_server-${VERSION}"
else
    exec mc-server-runner "${mcServerRunnerArgs[@]}" ./"bedrock_server-${VERSION}"
fi
