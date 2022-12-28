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

# framework - the works
./$USER-apps/new/common/$FRAMEWORK/$TEMPLATE/the_works.sh $FRAMEWORK $PASCAL $PROJECT $REPOSITORY $TEMPLATE $USER

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

# framework - add run scripts
./$USER-apps/new/common/$FRAMEWORK/common/add_run_scripts.sh $FRAMEWORK $KEBOB $PROJECT $REPOSITORY $TEMPLATE $TYPE $USER

popd

echo "Completed $SCRIPT"
