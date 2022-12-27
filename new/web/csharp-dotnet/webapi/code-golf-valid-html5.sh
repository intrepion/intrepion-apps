#!/usr/bin/env bash

SCRIPT=$0

echo "Running $SCRIPT"

pushd .

cd ..

FRAMEWORK=csharp-dotnet
KEBOB=code-golf-valid-html5
PASCAL=CodeGolfValidHtml5
TEMPLATE=webapi
TYPE=web
USER=intrepion

PROJECT=${PASCAL}WebApi

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
./$USER-apps/new/$TYPE/$FRAMEWORK/$TEMPLATE/common/remove_boilerplate.sh $PROJECT $REPOSITORY

# template - add health check
./$USER-apps/new/$TYPE/$FRAMEWORK/$TEMPLATE/common/add_health_check.sh $PROJECT $REPOSITORY

# project - add code golf valid html5
cd $REPOSITORY

FILE=$PROJECT/Controllers/CodeGolfValidHtml5Controller.cs

cat > $FILE <<EOF
using Microsoft.AspNetCore.Mvc;

namespace $PROJECT.Controllers;

[ApiController]
[Route("/")]
public class CodeGolfValidHtml5Controller : ControllerBase
{
    private readonly ILogger<CodeGolfValidHtml5Controller> _logger;

    public CodeGolfValidHtml5Controller(ILogger<CodeGolfValidHtml5Controller> logger)
    {
        _logger = logger;
    }

    [HttpGet(Name = "GetCodeGolfValidHtml5")]
    public ContentResult Get()
    {
        return new ContentResult 
        {
            ContentType = "text/html",
            Content = "<!DOCTYPE html><html lang=\"\"><meta charset=\"UTF-8\"><title>.</title>"
        };
    }
}
EOF

git add $FILE
git commit --message="Added code golf valid html5 controller."
git push --force

cd ..

# global - add run scripts
./$USER-apps/new/common/add_run_scripts.sh $FRAMEWORK $KEBOB $PROJECT $REPOSITORY $TEMPLATE $TYPE $USER

popd

echo "Completed $SCRIPT"
