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

TEMPLATE=webapi

APP=${PASCAL}WebApi
LIBRARY=${PASCAL}Library
SOLUTION=${PASCAL}App
STACK=web-csharp-dotnet-$TEMPLATE
TESTS=${PASCAL}Tests

REPO=intrepion-$KEBOB-$STACK

./intrepion-apps/new/web/csharp-dotnet/common/create_solution.sh $APP $LIBRARY $PASCAL $REPO $SOLUTION $TEMPLATE $TESTS
exit_on_error $? !!

echo "Adding health check."

cd $REPO

FILE=$APP/Controllers/HealthCheckController.cs

if [ -f $FILE ]; then
    echo "File $FILE already exists."
    exit 1
fi

cat > $FILE <<EOF
using Microsoft.AspNetCore.Mvc;

namespace $APP.Controllers;

[ApiController]
[Route("[controller]")]
public class HealthCheckController : ControllerBase
{
    private readonly ILogger<HealthCheckController> _logger;

    public HealthCheckController(ILogger<HealthCheckController> logger)
    {
        _logger = logger;
    }

    [HttpGet(Name = "GetHealthCheck")]
    public string Get()
    {
        return "";
    }
}
EOF

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
