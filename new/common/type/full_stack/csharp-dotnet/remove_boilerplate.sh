#!/usr/bin/env bash

SCRIPT=$0
PASCAL=$1
REPOSITORY=$2

echo " - Running $SCRIPT $PASCAL $REPOSITORY"

if [ $# -ne 2 ]; then
  echo "usage: $SCRIPT <PASCAL> <REPOSITORY>"
  exit 1
fi

pushd .

cd $REPOSITORY
pwd

FILE=${PASCAL}Library/Class1.cs
rm -rf $FILE
git add $FILE

FILE=Intrepion.JsonRpc/Class1.cs
rm -rf $FILE
git add $FILE

FILE=${PASCAL}Tests/UnitTest1.cs
rm -rf $FILE
git add $FILE

FILE=${PASCAL}WebApi/Controllers/WeatherForecastController.cs
rm -rf $FILE
git add $FILE

FILE=${PASCAL}WebApi/WeatherForecast.cs
rm -rf $FILE
git add $FILE
git commit --message="Removed boilerplate."

popd

echo " - Completed $SCRIPT $PASCAL $REPOSITORY"
