#!/usr/bin/env bash

SCRIPT=$0
PROJECT=$1
REPOSITORY=$2

echo "Running $SCRIPT $PROJECT $REPOSITORY"

pushd .

cd $REPOSITORY

FILE=$PROJECT/Program.cs

sed -i '/app.MapGet("\/", () => "Hello World!");/iapp.MapGet("/HealthCheck", () => "");' $FILE

git add $FILE
git commit --message="Added health check."

popd

echo "Completed $SCRIPT $PROJECT $REPOSITORY"
