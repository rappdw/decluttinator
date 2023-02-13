#!/usr/bin/env bash

set -e

# define function that creates a commit with the message passed in by adding that message to the file passed in
function create_commit {
  echo "$1" > "$2"
  git add "$2"
  git commit -m "$1"
}

# create a temporary directory
REPO_DIR=$(mktemp -d)

pushd "$REPO_DIR"

# create a new repo
git init .

# create a main branch
git checkout -b main

create_commit "First commit on main" main.md
create_commit "Second commit on main" main.md

# create a develop branch
git checkout -b develop

create_commit "First commit on develop" develop.md
create_commit "Second commit on develop" develop.md

# create a feature branch
git checkout -b feature

create_commit "First commit on feature" feature.md

# merge feature into develop
git checkout develop
create_commit "Third commit on develop" develop.md
git merge -m "merge feature to develop" feature

git checkout main
create_commit "Third commit on main" main.md
create_commit "Fourth commit on main" main.md

# merge main into develop
git checkout develop
git merge -m "merge main into develop" main

# At this point, let's split the develop branch into a new repo
popd
OP_DIR=$(mktemp -d)

CONFIGURATION=$(cat <<-END
REPO=$REPO_DIR
HISTORICAL_REPO=$OP_DIR/historical
NEW_REPO=$OP_DIR/new
BRANCHES=develop
END
)

echo "$CONFIGURATION" > "$OP_DIR/config"

./split-repo.sh "$OP_DIR/config"

echo "$OP_DIR"