#!/usr/bin/env bash

SCRIPT=$0

echo "Running $SCRIPT"

pushd .

cd ..

FRAMEWORK=csharp-dotnet
KEBOB=hello-world
PASCAL=HelloWorld
TEMPLATE=web

PROJECT=${PASCAL}Web

REPOSITORY=intrepion-$KEBOB-web-$FRAMEWORK-$TEMPLATE

# framework - the works
./intrepion-apps/new/common/framework/$FRAMEWORK/$TEMPLATE/the_works.sh $FRAMEWORK $PASCAL $PROJECT $REPOSITORY $TEMPLATE

# project - fix grammar
cd $REPOSITORY
pwd

FILE=HelloWorldTests/HelloWorldTest.cs

cat > $FILE << EOF
using System.Net;
using Microsoft.AspNetCore.Mvc.Testing;

namespace HelloWorldTests;

public class HelloWorldTest : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient _client;

    public HelloWorldTest(WebApplicationFactory<Program> factory)
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

FILE=$PROJECT/Program.cs

sed -i 's/app.MapGet("\/", () => "Hello World!");/app.MapGet("\/", () => "Hello, world!");/' $FILE
git add $FILE
git commit --message "Fixed grammar."
git push --force

cd ..

# type - add run scripts
./intrepion-apps/new/common/type/web/$FRAMEWORK/add_run_scripts.sh $FRAMEWORK $KEBOB $PROJECT $REPOSITORY $TEMPLATE

popd

echo "Completed $SCRIPT"
