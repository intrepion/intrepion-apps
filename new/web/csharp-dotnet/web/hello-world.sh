#!/usr/bin/env bash

SCRIPT=$0

echo "Running $SCRIPT"

pushd .

cd ..

FRAMEWORK=csharp-dotnet
KEBOB=hello-world
PASCAL=HelloWorld
TEMPLATE=web
TYPE=web
USER=intrepion

PROJECT=${PASCAL}Web

REPOSITORY=$USER-$KEBOB-$TYPE-$FRAMEWORK-$TEMPLATE

# framework - the works
./$USER-apps/new/common/$FRAMEWORK/$TEMPLATE/the_works.sh $FRAMEWORK $PASCAL $PROJECT $REPOSITORY $TEMPLATE $USER

# project - fix grammar
cd $REPOSITORY

FILE=$PROJECT/Program.cs

sed -i 's/app.MapGet("\/", () => "Hello World!");/app.MapGet("\/", () => "Hello, world!");/' $FILE
git add $FILE
git commit --message "Fixed grammar."
git push --force

cd ..

# framework - add run scripts
./$USER-apps/new/common/$FRAMEWORK/add_run_scripts.sh $FRAMEWORK $KEBOB $PROJECT $REPOSITORY $TEMPLATE $TYPE $USER

popd

echo "Completed $SCRIPT"
