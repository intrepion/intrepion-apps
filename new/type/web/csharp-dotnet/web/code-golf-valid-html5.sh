#!/usr/bin/env bash

SCRIPT=$0

echo "Running $SCRIPT"

pushd .

cd ..

FRAMEWORK=csharp-dotnet
KEBOB=code-golf-valid-html5
PASCAL=CodeGolfValidHtml5
TEMPLATE=web

PROJECT=${PASCAL}Web

REPOSITORY=intrepion-$KEBOB-web-$FRAMEWORK-$TEMPLATE

# framework - the works
./intrepion-apps/new/common/framework/$FRAMEWORK/$TEMPLATE/the_works.sh $FRAMEWORK $PASCAL $PROJECT $REPOSITORY $TEMPLATE

# project - fix grammar
cd $REPOSITORY

FILE=CodeGolfValidHtml5Tests/CodeGolfValidHtml5Test.cs

cat > $FILE << EOF
using System.Net;
using Microsoft.AspNetCore.Mvc.Testing;

namespace CodeGolfValidHtml5Tests;

public class CodeGolfValidHtml5Test : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient _client;

    public CodeGolfValidHtml5Test(WebApplicationFactory<Program> factory)
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

FILE=$PROJECT/Program.cs

sed -i '/app.MapGet("\/", () => "Hello World!");/a\
app.MapGet("\/", context => {\
    context.Response.ContentType = "text\/html";\
    return context.Response.WriteAsync("<!DOCTYPE html><html lang=\\"\\"><meta charset=\\"UTF-8\\"><title>.</title>");\
});' $FILE
sed -i '/app.MapGet("\/", () => "Hello World!");/d' $FILE
git add $FILE
git commit --message "Added minimal HTML5 to pass validator."
git push --force

cd ..

# type - add run scripts
./intrepion-apps/new/common/type/web/$FRAMEWORK/add_run_scripts.sh $FRAMEWORK $KEBOB $PROJECT $REPOSITORY $TEMPLATE

popd

echo "Completed $SCRIPT"
