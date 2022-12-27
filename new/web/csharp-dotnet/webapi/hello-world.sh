#!/usr/bin/env bash

SCRIPT=$0

echo "Running $SCRIPT"

pushd .

cd ..

FRAMEWORK=csharp-dotnet
KEBOB=hello-world
PASCAL=HelloWorld
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

# project - add hello world
cd $REPOSITORY

FILE=$PROJECT/Controllers/HelloWorldController.cs

cat > $FILE <<EOF
using Microsoft.AspNetCore.Mvc;

namespace $PROJECT.Controllers;

[ApiController]
[Route("/")]
public class HelloWorldController : ControllerBase
{
    private readonly ILogger<HelloWorldController> _logger;

    public HelloWorldController(ILogger<HelloWorldController> logger)
    {
        _logger = logger;
    }

    [HttpGet(Name = "GetHelloWorld")]
    public string Get()
    {
        return "Hello, world!";
    }
}
EOF

git add $FILE
git commit --message="Added hello world controller."
git push --force

cd ..

# global - add run scripts
./$USER-apps/new/common/add_run_scripts.sh $FRAMEWORK $KEBOB $PROJECT $REPOSITORY $TEMPLATE $TYPE $USER

popd

echo "Completed $SCRIPT"
