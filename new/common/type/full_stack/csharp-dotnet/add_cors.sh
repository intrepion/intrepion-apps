#!/bin/bash

SCRIPT=$0
PASCAL=$1
PROJECT=$2
REPOSITORY=$3
TEMPLATE=$4

echo "Running $SCRIPT $PASCAL $PROJECT $REPOSITORY $TEMPLATE"

pushd .

cd $REPOSITORY
pwd

dotnet add ${PROJECT} package Microsoft.AspNetCore.Cors
git add ${PROJECT}
git commit --message "dotnet add ${PROJECT} package Microsoft.AspNetCore.Cors"

popd

echo "Completed $SCRIPT $PASCAL $PROJECT $REPOSITORY $TEMPLATE"
