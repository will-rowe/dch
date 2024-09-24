#!/usr/bin/env bash
set -e
trap 'echo "An error occurred when trying to run a devcontainer. Exiting..."; exit 1;' ERR

usage() {
    echo "Usage: dch.sh -r /path/repo -d /path/custom.dockerfile"
    exit 1
}

make_absolute_path() {
    local input_path="$1"
    if [[ -z "$input_path" ]]; then
        echo "Error: No path provided."
        return 1
    fi
    if [[ "$input_path" == /* ]]; then
        echo "$input_path"
        return 0
    fi
    p=$(cd "$(dirname "$input_path")" && pwd)
    d=$(basename "$input_path")
    echo "$p/$d"
}

DC_REPO=""
DC_PATH=""
if [ -L "$0" ]; then
  DC_PATH="$(cd "$(dirname "$(readlink -f "$0")")"; pwd)"
else
  DC_PATH="$(cd "$(dirname "$0")"; pwd)"
fi

DC_CONFIG="${DC_PATH}/devcontainer.json"
DC_DOCKERFILE="${DC_PATH}/go.Dockerfile"
DC_ZSHRC="${DC_PATH}/.zshrc"

# Parse CLI opts
repo_required=false
while getopts "r:d:" opt; do
  case $opt in
    r)
      DC_REPO="$OPTARG"
      repo_required=true
      ;;
    d)
      DC_DOCKERFILE="$OPTARG"
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done
if ! $repo_required; then
    echo "error: -r required"
    usage
fi

# Work out if initialisation needed
DC_REPO=$(make_absolute_path "$DC_REPO")
DC_REPO_NAME=$(basename "$DC_REPO")
INIT_REPO=false
INIT_DEVCONTAINER=false
echo "repository name: ${DC_REPO_NAME}"
echo "repository path: ${DC_REPO}"
echo "dockerfile: ${DC_DOCKERFILE}"

if [[ -d "$DC_REPO/.devcontainer" ]]; then
    echo "using the existing devcontainer for ${DC_REPO_NAME}"
else
  if [[ -d "$DC_REPO" ]]; then
    echo "no devcontainer found in ${DC_REPO_NAME}, will create"
    INIT_DEVCONTAINER=true
  else
    echo "no ${DC_REPO_NAME} repo detected, will create"
    INIT_REPO=true
    INIT_DEVCONTAINER=true
  fi
fi

# Create the repo and devcontainer if necessary
if [[ "$INIT_REPO" == true ]]; then
  echo "creating ${DC_REPO_NAME} repo"
  mkdir -p ${DC_REPO}
fi
pushd "$DC_REPO"
if [[ "$INIT_DEVCONTAINER" == true ]]; then
  echo "creating devcontainer for repo"
  mkdir .devcontainer
  pushd ./.devcontainer
  cp "${DC_DOCKERFILE}" ./Dockerfile
  cp  "${DC_ZSHRC}" ./.zshrc
  jq --arg dc_repo "$DC_REPO" --arg dc_repo_name "$DC_REPO_NAME" '.mounts |= map(gsub("\\$\\{DC_REPO\\}"; $dc_repo) | gsub("\\$\\{DC_REPO_NAME\\}"; $dc_repo_name)) | .workspaceFolder |= gsub("\\$\\{DC_REPO_NAME\\}"; $dc_repo_name)' "${DC_CONFIG}" > ./devcontainer.json
  popd
fi

# Open VSCode using the devcontainer
code . --new-window
