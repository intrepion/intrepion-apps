#!/usr/bin/env bash

SCRIPT=$0
PROJECT=$1
REPOSITORY=$2

echo "Running $SCRIPT $PROJECT $REPOSITORY"

pushd .

cd $REPOSITORY

FILE=$PROJECT/Controllers/WeatherForecastController.cs
rm -rf $FILE
git add $FILE

FILE=$PROJECT/WeatherForecast.cs
rm -rf $FILE
git add $FILE

git commit --message="Removed boilerplate."

popd

echo "Completed $SCRIPT $PROJECT $REPOSITORY"
