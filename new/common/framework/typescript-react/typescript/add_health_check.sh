#!/usr/bin/env bash

SCRIPT=$0
REPOSITORY=$1

echo "Running $SCRIPT $REPOSITORY"

pushd .

cd $REPOSITORY
pwd

popd

echo "Completed $SCRIPT $REPOSITORY"
