#!/usr/bin/env bash

SCRIPT=$0

echo "Running $SCRIPT"

pushd .

cd ..

FRAMEWORK=csharp-dotnet
KEBOB=code-golf-valid-html5
PASCAL=CodeGolfValidHtml5
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

sed -i '/app.MapGet("\/", () => "Hello World!");/a\
app.MapGet("\/", context => {\
    context.Response.ContentType = "text\/html";\
    return context.Response.WriteAsync("<!DOCTYPE html><html lang=\\"\\"><meta charset=\\"UTF-8\\"><title>.</title>");\
});' $FILE
sed -i '/app.MapGet("\/", () => "Hello World!");/d' $FILE
git add $FILE
git commit --message "Added minimal HTML5 to pass validator."
git push --force

cd ..

# framework - add run scripts
./$USER-apps/new/common/$FRAMEWORK/add_run_scripts.sh $FRAMEWORK $KEBOB $PROJECT $REPOSITORY $TEMPLATE $TYPE $USER

popd

echo "Completed $SCRIPT"
