#!/usr/bin/env bash

SCRIPT=$0
REPOSITORY=$1

echo "Running $SCRIPT $REPOSITORY"

pushd .

cd $REPOSITORY

popd

echo "Completed $SCRIPT $REPOSITORY"
