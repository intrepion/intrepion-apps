#!/usr/bin/env bash

SCRIPT=$0
PROJECT=$1
REPOSITORY=$2

echo " - Running $SCRIPT $PROJECT $REPOSITORY"

if [ $# -ne 2 ]; then
  echo "usage: $SCRIPT <PROJECT> <REPOSITORY>"
  exit 1
fi

pushd .

cd $REPOSITORY
pwd

FILE=$PROJECT/Program.cs

cat << EOF >> $FILE

public partial class Program {}
EOF

git add $FILE
git commit -m "Added public partial to Program class.";

sed -i '/app.MapGet("\/", () => "Hello World!");/iapp.MapGet("/HealthCheck", () => "");' $FILE

git add $FILE
git commit --message="Added health check."

popd

echo " - Completed $SCRIPT $PROJECT $REPOSITORY"
