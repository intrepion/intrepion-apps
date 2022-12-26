#!/usr/bin/env bash

SCRIPT=$0
KEBOB=$1
PASCAL=$2

if [ -z $KEBOB ]; then
    echo "usage: $SCRIPT <kebob-case> <PascalCase>"
    exit 1
fi

if [ -z $PASCAL ]; then
    echo "usage: $SCRIPT <kebob-case> <PascalCase>"
    exit 1
fi

echo "$SCRIPT $KEBOB $PASCAL"

CURRENT=$(date +%Y-%m-%d-%H-%M-%S-%N)
TEMPLATE=web
PROJECT=${PASCAL}Web
USER=intrepion

STACK=web-csharp-dotnet-$TEMPLATE

REPOSITORY=$USER-$KEBOB-$STACK

cd ..

source ./$USER-apps/new/functions.sh

./$USER-apps/new/web/csharp-dotnet/common/create_branch.sh $CURRENT $REPOSITORY $USER

./$USER-apps/new/web/csharp-dotnet/common/create_commands.sh $PASCAL $REPOSITORY

./$USER-apps/new/web/csharp-dotnet/common/create_app.sh $PASCAL $PROJECT $REPOSITORY $TEMPLATE

echo "Adding health check."

cd $REPOSITORY

FILE=$PROJECT/Program.cs

exit_if_file_does_not_exist $FILE

sed -i '/app.MapGet("\/", () => "Hello World!");/iapp.MapGet("/HealthCheck", () => "");' $FILE

git add --all
git commit --message="Added health check."

cd ..

echo "Successfully added health check."

./$USER-apps/new/web/csharp-dotnet/common/create_digital_ocean_files.sh $CURRENT $PASCAL $REPOSITORY $USER

./$USER-apps/new/create_run_script.sh $KEBOB $PROJECT $REPOSITORY $STACK

echo "$SCRIPT $KEBOB $PASCAL successful."
