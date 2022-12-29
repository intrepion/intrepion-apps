#!/usr/bin/env bash

SCRIPT=$0

echo "Running $SCRIPT"

pushd .

cd ..

FRAMEWORK=csharp-dotnet
KEBOB=code-golf-valid-html5
PASCAL=CodeGolfValidHtml5
TEMPLATE=web

PROJECT=${PASCAL}Web

REPOSITORY=intrepion-$KEBOB-web-$FRAMEWORK-$TEMPLATE

# framework - the works
./intrepion-apps/new/common/framework/$FRAMEWORK/$TEMPLATE/the_works.sh $FRAMEWORK $PASCAL $PROJECT $REPOSITORY $TEMPLATE

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

# type - add run scripts
./intrepion-apps/new/common/type/web/$FRAMEWORK/add_run_scripts.sh $FRAMEWORK $KEBOB $PROJECT $REPOSITORY $TEMPLATE

popd

echo "Completed $SCRIPT"
