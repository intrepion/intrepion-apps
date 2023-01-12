#!/bin/bash

SCRIPT=$0
REPOSITORY=$1

echo " - Running $SCRIPT $REPOSITORY"

pushd .

if [ ! -d "$REPOSITORY" ]; then
  git clone git@github.com:intrepion/$REPOSITORY.git
fi

cd $REPOSITORY
pwd

git checkout main

FIRST=`git rev-list --max-parents=0 HEAD`
git reset --hard $FIRST
git clean -d --force

popd

echo " - Completed $SCRIPT $REPOSITORY"
