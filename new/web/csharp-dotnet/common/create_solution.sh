#!/usr/bin/env bash

exit_on_error() {
    exit_code=$1
    last_command=${@:2}
    if [ $exit_code -ne 0 ]; then
        >&2 echo "\"${last_command}\" command failed with exit code ${exit_code}."
        exit $exit_code
    fi
}

set -o history -o histexpand

APP=$1
LIBRARY=$2
PASCAL=$3
REPO=$4
SOLUTION=$5
TEMPLATE=$6
TESTS=$7

pushd .

FOLDER=$REPO

if [ -d $FOLDER ]; then
    echo "Directory $FOLDER already exists"
    exit 1
fi

git clone git@github.com:intrepion/$REPO.git
exit_on_error $? !!

cd $REPO

FILE=.gitignore

if [ -f $FILE ]; then
    echo "File $FILE already exists."
    exit 1
fi

dotnet new gitignore
exit_on_error $? !!
git add --all
exit_on_error $? !!
git commit --message="dotnet new gitignore"
exit_on_error $? !!

FILE=$SOLUTION.sln

if [ -f $FILE ]; then
    echo "File $FILE already exists."
    exit 1
fi

dotnet new sln --name $SOLUTION
exit_on_error $? !!
git add --all
exit_on_error $? !!
git commit --message="dotnet new sln --name $SOLUTION"
exit_on_error $? !!

LIBRARY=${PASCAL}Library
FOLDER=$LIBRARY

if [ -d $FOLDER ]; then
    echo "Directory $FOLDER already exists"
    exit 1
fi

dotnet new classlib --name $FOLDER
exit_on_error $? !!
git add --all
exit_on_error $? !!
git commit --message="dotnet new classlib --name $FOLDER"
exit_on_error $? !!
dotnet sln add $FOLDER
git add --all
exit_on_error $? !!
git commit --message="dotnet sln add $FOLDER"
exit_on_error $? !!

TESTS=${PASCAL}Tests
FOLDER=$TESTS

if [ -d $FOLDER ]; then
    echo "Directory $FOLDER already exists"
    exit 1
fi

dotnet new xunit --name $FOLDER
exit_on_error $? !!
git add --all
exit_on_error $? !!
git commit --message="dotnet new xunit --name $FOLDER"
exit_on_error $? !!
dotnet sln add $FOLDER
git add --all
exit_on_error $? !!
git commit --message="dotnet sln add $FOLDER"
exit_on_error $? !!
dotnet add $FOLDER reference $LIBRARY
git add --all
exit_on_error $? !!
git commit --message="dotnet add $FOLDER reference $LIBRARY"
exit_on_error $? !!

FOLDER=$APP

if [ -d $FOLDER ]; then
    echo "Directory $FOLDER already exists"
    exit 1
fi

dotnet new $TEMPLATE --name $FOLDER
exit_on_error $? !!
git add --all
exit_on_error $? !!
git commit --message="dotnet new $TEMPLATE --name $FOLDER"
exit_on_error $? !!
dotnet sln add $FOLDER
git add --all
exit_on_error $? !!
git commit --message="dotnet sln add $FOLDER"
exit_on_error $? !!
dotnet add $FOLDER reference $LIBRARY
git add --all
exit_on_error $? !!
git commit --message="dotnet add $FOLDER reference $LIBRARY"
exit_on_error $? !!

popd
