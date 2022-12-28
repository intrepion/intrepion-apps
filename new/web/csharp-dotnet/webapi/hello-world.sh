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

# framework - the works
./$USER-apps/new/common/framework/$FRAMEWORK/$TEMPLATE/the_works.sh $FRAMEWORK $PASCAL $PROJECT $REPOSITORY $TEMPLATE $USER

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

# type - add run scripts
./$USER-apps/new/common/type/$TYPE/$FRAMEWORK/add_run_scripts.sh $FRAMEWORK $KEBOB $PROJECT $REPOSITORY $TEMPLATE $TYPE $USER

popd

echo "Completed $SCRIPT"
