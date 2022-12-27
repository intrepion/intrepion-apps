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

# global - checkout first commit
./$USER-apps/new/common/checkout_first_commit.sh $REPOSITORY $USER

# framework - add template files
./$USER-apps/new/$TYPE/$FRAMEWORK/common/add_template_files.sh $PASCAL $PROJECT $REPOSITORY $TEMPLATE

# framework - add local commands
./$USER-apps/new/$TYPE/$FRAMEWORK/common/add_local_commands.sh $PROJECT $REPOSITORY

# framework - add deployment files
./$USER-apps/new/$TYPE/$FRAMEWORK/common/add_deployment_files.sh $PASCAL $PROJECT $REPOSITORY $USER

# template - remove boilerplate
./$USER-apps/new/$TYPE/$FRAMEWORK/$TEMPLATE/common/remove_boilerplate.sh

# template - add health check
./$USER-apps/new/$TYPE/$FRAMEWORK/$TEMPLATE/common/add_health_check.sh $PROJECT $REPOSITORY

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

# global - add run scripts
./$USER-apps/new/common/add_run_scripts.sh $FRAMEWORK $KEBOB $PROJECT $REPOSITORY $TEMPLATE $TYPE $USER

popd

echo "Completed $SCRIPT"
