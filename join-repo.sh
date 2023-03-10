#!/usr/bin/env bash

set -e

# get command line argument
if [ $# -ne 1 ]; then
  echo "Usage: $0 <config_file>"
  exit 1
fi

# shellcheck disable=SC2034
DIR=$(dirname "$(readlink -f "$0")")

# set environment variables from config file
# shellcheck disable=SC1090
source "$1"

# test to ensure REPO and NEW_REPO in environment
if [[ -z "$JOINED_PATH" || -z "$HISTORICAL_REPO" || -z "$NEW_REPO" || -z "$BRANCHES" ]]; then
  echo "config file must specify, REPO, HISTORICAL_REPO, NEW_REPO, and BRANCHES."
  exit 1
fi

git clone --no-local "$NEW_REPO" "$JOINED_PATH"
pushd "$JOINED_PATH"
git remote add history "$HISTORICAL_REPO"
git remote set-url --push history '** PUSH DISABLED **'
git fetch history


for BRANCH in $BRANCHES; do
  BRANCH_TAIL=$(git rev-list -n 1 decluttinator/initial/"$BRANCH")
  BRANCH_HISTORY_TIP=$(git rev-list -n 1 decluttinator/terminal/"$BRANCH")
  # graft the new repo history onto the historical repo
  git replace --graft "$BRANCH_TAIL" "$BRANCH_HISTORY_TIP"
done
