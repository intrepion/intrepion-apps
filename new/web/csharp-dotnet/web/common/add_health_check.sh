#!/usr/bin/env bash

SCRIPT=$0
PROJECT=$1
REPOSITORY=$2

echo "Running $SCRIPT $PROJECT $REPOSITORY"

pushd .

cd $REPOSITORY

sed -i '/app.MapGet("\/", () => "Hello World!");/iapp.MapGet("/HealthCheck", () => "");' $PROJECT/Program.cs

git add $PROJECT/Program.cs
git commit --message="Added health check."

popd

echo "Completed $SCRIPT $PROJECT $REPOSITORY"
