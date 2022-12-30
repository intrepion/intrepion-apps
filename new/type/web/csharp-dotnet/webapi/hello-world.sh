#!/usr/bin/env bash

SCRIPT=$0

echo "Running $SCRIPT"

pushd .

cd ..

FRAMEWORK=csharp-dotnet
KEBOB=hello-world
PASCAL=HelloWorld
TEMPLATE=webapi

PROJECT=${PASCAL}WebApi

REPOSITORY=intrepion-$KEBOB-web-$FRAMEWORK-$TEMPLATE

# framework - the works
./intrepion-apps/new/common/framework/$FRAMEWORK/$TEMPLATE/the_works.sh $FRAMEWORK $PASCAL $PROJECT $REPOSITORY $TEMPLATE

# project - add hello world
cd $REPOSITORY

mkdir -p HelloWorldTests/Controllers

FILE=HelloWorldTests/Controllers/HelloWorldControllerTest.cs

cat > $FILE << EOF
using System.Net;
using Microsoft.AspNetCore.Mvc.Testing;

namespace HelloWorldTests.Controllers;

public class HelloWorldControllerTest : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient _client;

    public HelloWorldControllerTest(WebApplicationFactory<Program> factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task TestGetHelloWorld()
    {
        // Arrange
        var expected = "Hello, world!";

        // Act
        var response = await _client.GetAsync("/");
        var actual = await response.Content.ReadAsStringAsync();

        // Assert
        response.EnsureSuccessStatusCode();
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Equal(expected, actual);
    }
}
EOF

git add $FILE
git commit --message="Added hello world controller tests."

FILE=HelloWorldWebApi/Controllers/HelloWorldController.cs

cat > $FILE << EOF
using Microsoft.AspNetCore.Mvc;

namespace HelloWorldWebApi.Controllers;

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
./intrepion-apps/new/common/type/web/$FRAMEWORK/add_run_scripts.sh $FRAMEWORK $KEBOB $PROJECT $REPOSITORY $TEMPLATE

popd

echo "Completed $SCRIPT"
