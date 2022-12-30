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

mkdir -p ${PASCAL}Tests/UnitTests

FILE=${PASCAL}Tests/UnitTests/SayingHelloTest.cs

cat > $FILE <<EOF
using SayingHelloLibrary.Domain;

namespace SayingHelloTests.UnitTests;

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

mkdir -p ${PASCAL}Library/Domain

FILE=${PASCAL}Library/Domain/SayingHello.cs

cat > $FILE <<EOF
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

FILE=$PROJECT/Controllers/HelloWorldController.cs

cat > $FILE <<EOF
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
