#!/usr/bin/env bash

SCRIPT=$0

echo " - Running $SCRIPT"

pushd .

cd ..

FRAMEWORK=csharp-dotnet
KEBOB=code-golf-valid-html5
PASCAL=CodeGolfValidHtml5
TEMPLATE=webapi

PROJECT=${PASCAL}WebApi

REPOSITORY=intrepion-$KEBOB-web-$FRAMEWORK-$TEMPLATE

# framework - the works
./intrepion-apps/new/common/framework/$FRAMEWORK/$TEMPLATE/the_works.sh $FRAMEWORK $PASCAL $PROJECT $REPOSITORY $TEMPLATE

# project - add code golf valid html5
cd $REPOSITORY
pwd

mkdir -p CodeGolfValidHtml5Tests/Controllers

FILE=CodeGolfValidHtml5Tests/Controllers/CodeGolfValidHtml5ControllerTest.cs
cat > $FILE << EOF
using System.Net;
using Microsoft.AspNetCore.Mvc.Testing;

namespace CodeGolfValidHtml5Tests.Controllers;

public class CodeGolfValidHtml5ControllerTest : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient _client;

    public CodeGolfValidHtml5ControllerTest(WebApplicationFactory<Program> factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task TestGetCodeGolfValidHtml5()
    {
        // Arrange
        var expected = "<!DOCTYPE html><html lang=\"\"><meta charset=\"UTF-8\"><title>.</title>";

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

FILE=$PROJECT/Controllers/CodeGolfValidHtml5Controller.cs
cat > $FILE << EOF
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

# type - add run scripts
./intrepion-apps/new/common/type/web/$FRAMEWORK/add_run_scripts.sh $FRAMEWORK $KEBOB $PROJECT $REPOSITORY $TEMPLATE

popd

echo " - Completed $SCRIPT"
