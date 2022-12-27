#!/usr/bin/env bash

SCRIPT=$0
PROJECT=$1
REPOSITORY=$2

echo "Running $SCRIPT $PROJECT $REPOSITORY"

pushd .

cd $REPOSITORY

FILE=$PROJECT/Controllers/HealthCheckController.cs

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

git add $FILE
git commit --message="Added health check."

popd

echo "Completed $SCRIPT $PROJECT $REPOSITORY"
