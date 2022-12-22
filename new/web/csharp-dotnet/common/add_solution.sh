#!/usr/bin/env bash

APP=$1
LIBRARY=$2
PASCAL=$3
REPO=$4
SOLUTION=$5
TEMPLATE=$6
TESTS=$7

source ./intrepion-apps/new/functions.sh

pushd .

FOLDER=$REPO

exit_if_folder_exists $FOLDER

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

FOLDER=$LIBRARY

exit_if_folder_exists $FOLDER

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

FOLDER=$TESTS

exit_if_folder_exists $FOLDER

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

exit_if_folder_exists $FOLDER

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
