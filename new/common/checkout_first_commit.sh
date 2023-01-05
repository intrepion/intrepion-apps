#!/bin/bash

SCRIPT=$0
REPOSITORY=$1

echo " - Running $SCRIPT $REPOSITORY"

pushd .

# Check if the specified folder exists
if [ ! -d "$REPOSITORY" ]; then
  # If the folder does not exist, clone the repository using SSH
  git clone git@github.com:intrepion/$REPOSITORY.git
fi

# Navigate to the repository folder
cd $REPOSITORY
pwd

# Checkout main branch
git checkout main

# Reset to first commit
FIRST=`git rev-list --max-parents=0 HEAD`
git reset --hard $FIRST
git clean -d --force

popd

echo " - Completed $SCRIPT $REPOSITORY"
