#!/usr/bin/env bash

SCRIPT=$0
PASCAL=$1
PROJECT=$2
REPOSITORY=$3

echo "Running $SCRIPT $PASCAL $PROJECT $REPOSITORY"

pushd .

cd $REPOSITORY

FILE=${PASCAL}Library/Class1.cs
rm -rf $FILE
git add $FILE

FILE=${PASCAL}Tests/UnitTest1.cs
rm -rf $FILE
git add $FILE

FILE=$PROJECT/Controllers/WeatherForecastController.cs
rm -rf $FILE
git add $FILE

FILE=$PROJECT/WeatherForecast.cs
rm -rf $FILE
git add $FILE

git commit --message="Removed boilerplate."

popd

echo "Completed $SCRIPT $PASCAL $PROJECT $REPOSITORY"
