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

TEMPLATE=web

APP=${PASCAL}Web
LIBRARY=${PASCAL}Library
SOLUTION=${PASCAL}App
STACK=web-csharp-dotnet-$TEMPLATE
TESTS=${PASCAL}Tests

REPO=intrepion-$KEBOB-$STACK

./intrepion-apps/new/web/csharp-dotnet/common/create_solution.sh $APP $LIBRARY $PASCAL $REPO $SOLUTION $TEMPLATE $TESTS
exit_on_error $? !!

echo "Adding health check."

cd $REPO

FILE=$APP/Program.cs

if [ ! -f $FILE ]; then
    echo "File $FILE does not exist."
    exit 1
fi

sed -i '/app.MapGet("\/", () => "Hello World!");/iapp.MapGet("/HealthCheck", () => "");' $FILE

git add --all
exit_on_error $? !!
git commit --message="Added health check."
exit_on_error $? !!

cd ..

echo "Successfully added health check."

./intrepion-apps/new/web/csharp-dotnet/common/create_digital_ocean_files.sh $APP $LIBRARY $REPO $TESTS
exit_on_error $? !!

./intrepion-apps/new/web/csharp-dotnet/common/add_run_script.sh $APP $KEBOB $PASCAL $REPO $SCRIPT $STACK
exit_on_error $? !!

echo "$SCRIPT $KEBOB $PASCAL successful."
