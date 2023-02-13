#!/usr/bin/env bash

set -e

# get command line argument
if [ $# -ne 1 ]; then
  echo "Usage: $0 <config_file>"
  exit 1
fi

COMMIT_MESSAGE=$(cat <<-END
Split branch BRANCH from the historical repo

This is the last commit on the BRANCH branch of the historical repo and the first commit on
that branch in the new repo.

Should you desire to view the work in the new repository in historical context, you can still
do so. Use join-repo.sh or do the following

1. git clone <new_repo_url> <path_to_view_in_context>
2. cd <path_to_view_in_context>
3. git remote add historical <historical_repo_url>
4. git fetch historical
5. git replace $(git rev-list -n 1 decluttinator/initial/BRANCH) $(git rev-list -n 1 decluttinator/terminal/BRANCH)
END
)

# set environment variables from config file
# shellcheck disable=SC1090
source "$1"

# test to ensure REPO and NEW_REPO in environment
if [[ -z "$REPO" || -z "$HISTORICAL_REPO" || -z "$NEW_REPO" || -z "$BRANCHES" ]]; then
  echo "config file must specify, REPO, HISTORICAL_REPO, NEW_REPO, and BRANCHES."
  exit 1
fi

# clone the repo we are going to split
git clone --bare --no-local "$REPO" "$HISTORICAL_REPO"
pushd "$HISTORICAL_REPO"

# for each branch, identify the last commit within the historical repo. Create a final commit on those
# branches that has info about the split. For completeness we also create a tag for that final commit
for BRANCH in $BRANCHES; do
  TIP=$(git rev-list -n 1 "$BRANCH")
  # create terminal commit for existing branch
  # shellcheck disable=SC2001
  BRANCH_COMMIT_MESSAGE=$(sed "s|BRANCH|$BRANCH|g" <<< "$COMMIT_MESSAGE")
  TERMINAL_TIP=$(git commit-tree -m "$BRANCH_COMMIT_MESSAGE" -p "$TIP" "$TIP^{tree}")
  git tag -a decluttinator/terminal/"$BRANCH" -m "Final commit on $BRANCH branch" "$TERMINAL_TIP"
  git update-ref refs/heads/"$BRANCH" "$TERMINAL_TIP"
done

popd
TEMP_REPO=$HISTORICAL_REPO.tmp
git clone --no-local "$HISTORICAL_REPO" "$TEMP_REPO"
pushd "$TEMP_REPO"

for BRANCH in $BRANCHES; do
  git checkout "$BRANCH"
  TIP=$(git rev-list -n 1 "$BRANCH")
  TIP_PARENT=$(git rev-list -n 1 --skip=1 "$BRANCH")
  # create the new branch of development (parentless)
  # shellcheck disable=SC2001
  BRANCH_COMMIT_MESSAGE=$(sed "s|BRANCH|$BRANCH|g" <<< "$COMMIT_MESSAGE")
  NEW_TREE=$(git commit-tree -m "$BRANCH_COMMIT_MESSAGE" "$TIP_PARENT^{tree}")
  git rebase --onto "$NEW_TREE" "$TIP"
  git tag -a decluttinator/initial/"$BRANCH" -m "Initial commit on $BRANCH branch" "$NEW_TREE"
done

popd

mkdir -p "$NEW_REPO"
pushd "$NEW_REPO"
git --bare init
popd
pushd "$TEMP_REPO"
git remote add declutter "$NEW_REPO"

for BRANCH in $BRANCHES; do
  git push -u declutter "$BRANCH"
  git push -u declutter decluttinator/initial/"$BRANCH"
done

popd

rm -rf "$TEMP_REPO"

GREEN='\033[0;32m'
NC='\033[0m' # No Color

function final_cleanup {
  pushd "$1"
  git reflog expire --expire=now --all
  git gc --prune=now
  popd
}

if [[ -z "$SLIMMED_PATH" ]]; then
  final_cleanup "$HISTORICAL_REPO"
  final_cleanup "$NEW_REPO"
  echo ""
  echo ""
  echo -e "${GREEN}New repo is available at ${NC}$NEW_REPO${GREEN}."
  echo -e "Historical repo is available at ${NC}$HISTORICAL_REPO"
  echo ""
  echo "If you are satisfied with the results you should push $HISTORICAL_REPO back to origin"
  echo ""
  echo "Work still needs to be done to remove the cruft in $NEW_REPO"
  echo "run slim-repo.sh against the new_repo_dir to do so."
  echo ""
  echo "Once that is complete, $NEW_REPO can be pushed to a new repo on the server."
else
  final_cleanup "$HISTORICAL_REPO"

  DIR=$(dirname "$(readlink -f "$0")")
  "$DIR"/slim-repo.sh "$1"
  rm -rf "$NEW_REPO"
  git clone --bare --no-local "$SLIMMED_PATH" "$NEW_REPO"
  rm -rf "$SLIMMED_PATH"
  pushd "$NEW_REPO"
  git remote remove origin
  popd

  echo ""
  echo ""
  echo -e "${GREEN}New repo is available at ${NC}$NEW_REPO${GREEN}."
  echo -e "Historical repo is available at ${NC}$HISTORICAL_REPO"
  echo ""
  echo "If you are satisfied with the results you should push $HISTORICAL_REPO back to origin and"
  echo "push $NEW_REPO to a new repo on the server."
fi
