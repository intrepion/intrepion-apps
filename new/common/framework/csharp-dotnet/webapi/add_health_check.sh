#!/usr/bin/env bash

SCRIPT=$0
PASCAL=$1
REPOSITORY=$2

echo "Running $SCRIPT $PASCAL $REPOSITORY"

pushd .

cd $REPOSITORY

FILE=${PASCAL}WebApi/Program.cs

cat << EOF >> $FILE

public partial class Program {}
EOF

git add $FILE
git commit -m "Added public partial to Program class.";

mkdir -p ${PASCAL}Tests/Controllers

FILE=${PASCAL}Tests/Controllers/HealthCheckControllerTest.cs

cat > $FILE << EOF
using System.Net;
using Microsoft.AspNetCore.Mvc.Testing;

namespace ${PASCAL}Tests.Controllers;

public class HealthCheckControllerTest : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient _client;

    public HealthCheckControllerTest(WebApplicationFactory<Program> factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task TestGetHealthCheck()
    {
        // Arrange
        var expected = "";

        // Act
        var response = await _client.GetAsync("/HealthCheck");
        var actual = await response.Content.ReadAsStringAsync();

        // Assert
        response.EnsureSuccessStatusCode();
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Equal(expected, actual);
    }
}
EOF

git add $FILE
git commit --message="Added health check controller tests."

FILE=${PASCAL}WebApi/Controllers/HealthCheckController.cs

cat > $FILE << EOF
using Microsoft.AspNetCore.Mvc;

namespace ${PASCAL}WebApi.Controllers;

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
git commit --message="Added health check controller."

popd

echo "Completed $SCRIPT $PASCAL $REPOSITORY"
