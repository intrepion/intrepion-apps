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

echo "$SCRIPT $KEBOB $PASCAL"

CURRENT=$(date +%Y-%m-%d-%H-%M-%S-%N)
TEMPLATE=webapi
PROJECT=${PASCAL}WebApi
USER=intrepion

STACK=web-csharp-dotnet-$TEMPLATE

REPOSITORY=$USER-$KEBOB-$STACK

cd ..

source ./$USER-apps/new/functions.sh

./$USER-apps/new/web/csharp-dotnet/common/create_branch.sh $CURRENT $REPOSITORY $USER

./$USER-apps/new/web/csharp-dotnet/common/create_commands.sh $PASCAL $REPOSITORY

./$USER-apps/new/web/csharp-dotnet/common/create_app.sh $PASCAL $PROJECT $REPOSITORY $TEMPLATE

echo "Adding health check."

cd $REPOSITORY

FILE=$PROJECT/Controllers/WeatherForecastController.cs

exit_if_file_does_not_exist $FILE

rm -rf $FILE

git add --all
exit_on_error $? !!
git commit --message="Removing boilerplate."
exit_on_error $? !!

FILE=$PROJECT/Controllers/HealthCheckController.cs

exit_if_file_exists $FILE

cat > $FILE <<EOF
using Microsoft.AspNetCore.Mvc;

namespace $PROJECT.Controllers;

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

./$USER-apps/new/web/csharp-dotnet/common/create_digital_ocean_files.sh $CURRENT $PASCAL $REPOSITORY $USER

./$USER-apps/new/create_run_script.sh $KEBOB $PROJECT $REPOSITORY $STACK

echo "$SCRIPT $KEBOB $PASCAL successful."
