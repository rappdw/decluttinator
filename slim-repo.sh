#!/usr/bin/env bash

set -e

# get command line argument
if [ $# -ne 1 ]; then
  echo "Usage: $0 <config_file>"
  exit 1
fi

DIR=$(dirname "$(readlink -f "$0")")

# set environment variables from config file
# shellcheck disable=SC1090
source "$1"

# test to ensure REPO and NEW_REPO in environment
if [[ -z "$SLIMMED_PATH" || -z "$NEW_REPO" ]]; then
  echo "config file must specify, REPO, HISTORICAL_REPO, NEW_REPO, and BRANCHES."
  exit 1
fi

FILTER_EXTENSIONS=${FILTER_EXTENSIONS:-}
FILTER_ADDITIONAL=${FILTER_ADDITIONAL:-}

git clone --no-local "$NEW_REPO" "$SLIMMED_PATH"
pushd "$SLIMMED_PATH"
git filter-repo --analyze
"$DIR"/genfilter.py .git/filter-repo/analysis "$FILTER_EXTENSIONS" "$FILTER_ADDITIONAL"
git filter-repo --strip-blobs-with-ids .git/filter-repo/analysis/filtered_blobs.txt --invert-paths
git checkout --orphan decluttinator/filtered_files
mv .git/filter-repo/analysis/filtered_files.csv .
git add filtered_files.csv
git commit -m "Track files that were filtered out. You can retrieve them using the blob SHA-1 from $HISTORICAL_REPO."
popd
