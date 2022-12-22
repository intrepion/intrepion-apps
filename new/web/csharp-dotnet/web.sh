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

cd ..

source ./intrepion-apps/new/functions.sh

TEMPLATE=web

APP=${PASCAL}Web
LIBRARY=${PASCAL}Library
SOLUTION=${PASCAL}App
STACK=web-csharp-dotnet-$TEMPLATE
TESTS=${PASCAL}Tests

REPO=intrepion-$KEBOB-$STACK

./intrepion-apps/new/web/csharp-dotnet/common/add_solution.sh $APP $LIBRARY $PASCAL $REPO $SOLUTION $TEMPLATE $TESTS
exit_on_error $? !!

echo "Adding health check."

cd $REPO

FILE=$APP/Program.cs

exit_if_file_does_not_exist $FILE

sed -i '/app.MapGet("\/", () => "Hello World!");/iapp.MapGet("/HealthCheck", () => "");' $FILE

git add --all
exit_on_error $? !!
git commit --message="Added health check."
exit_on_error $? !!

cd ..

echo "Successfully added health check."

./intrepion-apps/new/web/csharp-dotnet/common/add_digital_ocean_files.sh $APP $LIBRARY $REPO $TESTS
exit_on_error $? !!

./intrepion-apps/new/add_run_script.sh $APP $KEBOB $REPO $SCRIPT $STACK
exit_on_error $? !!

echo "$SCRIPT $KEBOB $PASCAL successful."
