#!/usr/bin/env bash

SCRIPT=$0
REPOSITORY=$1

echo " - Running $SCRIPT $REPOSITORY"

if [ $# -ne 1 ]; then
  echo "usage: $SCRIPT <REPOSITORY>"
  exit 1
fi

pushd .

cd $REPOSITORY
pwd

mkdir -p .github/workflows

FILE=.github/workflows/dotnet.yml
cat > $FILE << EOF
# This workflow will build a .NET project
# For more information see: https://docs.github.com/en/actions/automating-builds-and-tests/building-and-testing-net

name: .NET

on:
  push:
    branches: [ "main" ]
  pull_request:
    branches: [ "main" ]

jobs:
  build:

    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v3
    - name: Setup .NET
      uses: actions/setup-dotnet@v3
      with:
        dotnet-version: 7.0.x
    - name: Restore dependencies
      run: dotnet restore
    - name: Build
      run: dotnet build --no-restore
    - name: Test
      run: dotnet test --no-build --verbosity normal
EOF
git add $FILE

FILE=README.md
cat << EOF >> $FILE

## CI/CD

[![.NET](https://github.com/intrepion/$REPOSITORY/actions/workflows/dotnet.yml/badge.svg?branch=main)](https://github.com/intrepion/$REPOSITORY/actions/workflows/dotnet.yml)
EOF
git add $FILE
git commit --message="Added GitHub Action files."

popd

echo " - Completed $SCRIPT $REPOSITORY"
