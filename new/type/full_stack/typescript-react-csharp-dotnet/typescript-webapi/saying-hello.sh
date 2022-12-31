#!/usr/bin/env bash

SCRIPT=$0

echo "Running $SCRIPT"

pushd .

cd ..

FRAMEWORK=csharp-dotnet
KEBOB=saying-hello
PASCAL=SayingHello
TEMPLATE=webapi

PROJECT=${PASCAL}WebApi

REPOSITORY=intrepion-$KEBOB-json-rpc-server-$FRAMEWORK-$TEMPLATE

# framework - the works
./intrepion-apps/new/common/type/full_stack/$FRAMEWORK/$TEMPLATE/the_works.sh $FRAMEWORK $PASCAL $PROJECT $REPOSITORY $TEMPLATE

# project - add saying hello
cd $REPOSITORY

mkdir -p SayingHelloTests/Domain

FILE=SayingHelloTests/Domain/SayingHelloTest.cs

cat > $FILE << EOF
using SayingHelloLibrary.Domain;

namespace SayingHelloTests.Domain;

public class SayingHelloTest
{
    [Theory]
    [InlineData("", "Hello, world!")]
    [InlineData("Oliver", "Hello, Oliver!")]
    public void TestSayHelloHappyPath(string name, string expected)
    {
        var result = SayingHello.SayHello(name);
        Assert.Equal(expected, result);
    }

    [Theory]
    [InlineData("   ", "Hello, world!")]
    [InlineData("Oliver  ", "Hello, Oliver!")]
    [InlineData("   Oliver", "Hello, Oliver!")]
    [InlineData("  Oliver ", "Hello, Oliver!")]
    public void TestSayHelloUnhappyPath(string name, string expected)
    {
        var result = SayingHello.SayHello(name);
        Assert.Equal(expected, result);
    }
}
EOF

git add $FILE
git commit --message="Added saying hello tests."

mkdir -p SayingHelloLibrary/Domain

FILE=SayingHelloLibrary/Domain/SayingHello.cs

cat > $FILE << EOF
namespace SayingHelloLibrary.Domain;

static public class SayingHello
{
    static public string SayHello(string name) {
        name = name.Trim();

        if (string.IsNullOrEmpty(name)) {
            name = "world";
        }

        return $"Hello, {name}!";
    }
}
EOF

git add $FILE
git commit --message="Added saying hello code."

mkdir -p SayingHelloTests/Controllers

FILE=SayingHelloTests/Controllers/SayingHelloControllerTest.cs

cat > $FILE << EOF
using System.Net;
using System.Text;
using Microsoft.AspNetCore.Mvc.Testing;

namespace SayingHelloTests.Controllers;

public class SayingHelloControllerTest : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient _client;

    public SayingHelloControllerTest(WebApplicationFactory<Program> factory)
    {
        _client = factory.CreateClient();
    }

    [Theory]
    [InlineData(\$\$$"""{"id":"00000000-0000-0000-0000-000000000000","jsonrpc":"2.0","params":{"name":"Oliver"}}""", \$\$$"""{"id":"00000000-0000-0000-0000-000000000000","jsonrpc":"2.0","result":{"saying":"Hello, Oliver!"}}""")]
    public async Task TestPostSayingHelloHappyPaths(string body, string expected)
    {
        // Arrange
        var requestBody = new StringContent(
            body,
            Encoding.UTF8,
            "application/json"
        );

        // Act
        var response = await _client.PostAsync("/", requestBody);
        var actual = await response.Content.ReadAsStringAsync();

        // Assert
        response.EnsureSuccessStatusCode();
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Equal(expected, actual);
    }
}
EOF

git add $FILE
git commit --message="Added saying hello controller tests."

FILE=SayingHelloWebApi/Controllers/SayingHelloController.cs

cat > $FILE << EOF
using Microsoft.AspNetCore.Mvc;

namespace SayingHelloWebApi.Controllers;

[ApiController]
[Route("/")]
public class SayingHelloController : ControllerBase
{
    private readonly ILogger<SayingHelloController> _logger;

    public SayingHelloController(ILogger<SayingHelloController> logger)
    {
        _logger = logger;
    }

    [HttpPost(Name = "PostSayingHello")]
    public string Post()
    {
        return \$\$$"""{"id":"00000000-0000-0000-0000-000000000000","jsonrpc":"2.0","result":{"saying":"Hello, Oliver!"}}""";
    }
}
EOF

git add $FILE
git commit --message="Added saying hello controller."
git push --force

cd ..

FRAMEWORK=typescript-react
TEMPLATE=typescript

REPOSITORY=intrepion-$KEBOB-json-rpc-client-web-$FRAMEWORK-$TEMPLATE

# framework - the works
./intrepion-apps/new/common/type/full_stack/$FRAMEWORK/$TEMPLATE/the_works.sh $FRAMEWORK $REPOSITORY $TEMPLATE

# project - add saying hello
cd $REPOSITORY

FILE=src/App.tsx

sed -i 's/  return <><\/>;/  return <>Hello, world!<\/>;/' $FILE
npx prettier --write .
git add $FILE
git commit --message "Added hello world text."
git push --force

cd ..

CLIENT="http://localhost:3000"
SERVER="http://localhost:80"

# type - add run scripts
./intrepion-apps/new/common/type/full_stack/typescript-react-typescript-csharp-dotnet-webapi/add_run_scripts.sh $CLIENT $KEBOB $PROJECT $SERVER

popd

echo "Completed $SCRIPT"
