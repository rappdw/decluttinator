#!/usr/bin/env bash

set -e

# define function that creates a commit with the message passed in by adding that message to the file passed in
function create_commit {
  echo "$1" > "$2"
  git add "$2" >/dev/null 2>&1
  git commit -m "$1" >/dev/null 2>&1
  git rev-parse HEAD
}

# create a temporary directory
OP_DIR=$(mktemp -d)
REPO_DIR="$OP_DIR/orig-repo"
mkdir -p "$REPO_DIR"

pushd "$REPO_DIR"

# create a new repo
git init .

# create a main branch
git checkout -b main

MAIN_1=$(create_commit "First commit on main" main.md)
MAIN_2=$(create_commit "Second commit on main" main.md)

# create a develop branch
git checkout -b develop

DEV_1=$(create_commit "First commit on develop" develop.md)
DEV_2=$(create_commit "Second commit on develop" develop.md)

# create a feature branch
git checkout -b feature

FEATURE_1=$(create_commit "First commit on feature" feature.md)

# merge feature into develop
git checkout develop
DEV_3=$(create_commit "Third commit on develop" develop.md)
git merge -m "merge feature to develop" feature

git checkout main
MAIN_3=$(create_commit "Third commit on main" main.md)
MAIN_4=$(create_commit "Fourth commit on main" main.md)

# merge main into develop
git checkout develop
git merge -m "merge main into develop" main

# At this point, let's split the develop branch into a new repo
popd

CONFIGURATION=$(cat <<-END
REPO=$REPO_DIR
HISTORICAL_REPO=$OP_DIR/historical
NEW_REPO=$OP_DIR/new
BRANCHES=develop
JOINED_PATH=$OP_DIR/join
END
)

echo "$CONFIGURATION" > "$OP_DIR/config"

echo "Splitting repo..."
./split-repo.sh "$OP_DIR/config"
echo ""
#echo "Joining repo..."
#./join-repo.sh "$OP_DIR/config"

pushd "$OP_DIR"

echo ""
echo ""
echo "*******************"
echo "Results of test are found in $OP_DIR"
echo "Ensure historical-clone and new-clone are as expected."

