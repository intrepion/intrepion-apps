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
    [InlineData("James", "Hello, James!")]
    [InlineData("Oliver", "Hello, Oliver!")]
    public void TestSayHelloHappyPath(string name, string expected)
    {
        // Arrange
        // Act
        var actual = SayingHello.SayHello(name).Saying;

        // Assert
        Assert.Equal(expected, actual);
    }

    [Theory]
    [InlineData("   ", "Hello, world!")]
    [InlineData("Oliver  ", "Hello, Oliver!")]
    [InlineData("   Oliver", "Hello, Oliver!")]
    [InlineData("  Oliver ", "Hello, Oliver!")]
    public void TestSayHelloUnhappyPath(string name, string expected)
    {
        // Arrange
        // Act
        var actual = SayingHello.SayHello(name).Saying;

        // Assert
        Assert.Equal(expected, actual);
    }
}
EOF

git add $FILE
git commit --message="Added saying hello tests."

mkdir -p SayingHelloLibrary/Domain

FILE=SayingHelloLibrary/Domain/FunctionCalls.cs

cat > $FILE << EOF
using SayingHelloLibrary.JsonRpc;

namespace SayingHelloLibrary.Domain;

public static class FunctionCalls
{
    public static Dictionary<string, FunctionCall> Dictionary = new Dictionary<string, FunctionCall>
    {
        { "say_hello", new FunctionCall
            {
                Function = (List<Parameter> parameters) => SayingHello.SayHello((string)parameters.First(p => p.Name == "name").Value),
                Parameters = new List<Parameter>
                {
                    new Parameter { Name = "name", Kind = "string" },
                }
            }
        },
    };
}
EOF

git add $FILE

FILE=SayingHelloLibrary/Domain/SayingHello.cs

cat > $FILE << EOF
namespace SayingHelloLibrary.Domain;

static public class SayingHello
{
    static public SayingHelloResult SayHello(string name) {
        name = name.Trim();

        if (string.IsNullOrEmpty(name)) {
            name = "world";
        }

        return new SayingHelloResult {
            Saying = $"Hello, {name}!"
        };
    }
}
EOF

git add $FILE

FILE=SayingHelloLibrary/Domain/SayingHelloResult.cs

cat > $FILE << EOF
using System.Text.Json.Serialization;

namespace SayingHelloLibrary.Domain;

public class SayingHelloResult
{
    [JsonPropertyName("saying")]
    public string Saying { get; set; }
}
EOF

git add $FILE

git commit --message="Added saying hello code."

mkdir -p SayingHelloTests/JsonRpc

FILE=SayingHelloTests/JsonRpc/SayingHelloJsonRpcTest.cs

cat > $FILE << EOF
using SayingHelloLibrary.Domain;
using SayingHelloLibrary.JsonRpc;

namespace SayingHelloTests.JsonRpc;

public class SayingHelloJsonRpcTest
{
    [Theory]
    [InlineData("", "Hello, world!")]
    [InlineData("James", "Hello, James!")]
    [InlineData("Oliver", "Hello, Oliver!")]
    public void TestSayingHelloJsonRpc_HappyPath(string name, string expected)
    {
        // Arrange
        var json = \$\$\$"""{"id":"1","jsonrpc":"2.0","method":"say_hello","params":{"name":"{{{name}}}"}}""";

        // Act
        var response = JsonRpcService.ProcessRequest(json, FunctionCalls.Dictionary);
        var actual = ((SayingHelloResult)response.Result).Saying;

        // Assert
        Assert.Equal("1", response.Id);
        Assert.Equal("2.0", response.JsonRpc);
        Assert.Equal(expected, actual);
    }
}
EOF

git add $FILE
git commit --message="Added json-rpc tests."

mkdir -p SayingHelloTests/Controllers

FILE=SayingHelloTests/Controllers/SayingHelloControllerTest.cs

cat > $FILE << EOF
using Microsoft.AspNetCore.Mvc.Testing;
using SayingHelloLibrary.Domain;
using SayingHelloLibrary.JsonRpc;
using System.Net;
using System.Text;
using System.Text.Json;

namespace SayingHelloTests.Controllers;

public class SayingHelloControllerTest : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient _client;

    public SayingHelloControllerTest(WebApplicationFactory<Program> factory)
    {
        _client = factory.CreateClient();
    }

    [Theory]
    [InlineData("", "Hello, world!")]
    [InlineData("James", "Hello, James!")]
    [InlineData("Oliver", "Hello, Oliver!")]
    public async Task TestPostSayingHello_HappyPaths(string name, string expected)
    {
        // Arrange
        var json = \$\$\$"""{"id":"1","jsonrpc":"2.0","method":"say_hello","params":{"name":"{{{name}}}"}}""";
        var requestBody = new StringContent(
            json,
            Encoding.UTF8,
            "application/json"
        );

        // Act
        var response = await _client.PostAsync("/", requestBody);
        var content = await response.Content.ReadAsStringAsync();
        var responseJsonRpc = JsonSerializer.Deserialize<JsonRpcResponse>(content);
        var sayingHelloJson = responseJsonRpc.Result.ToString();
        var sayingHelloResult = JsonSerializer.Deserialize<SayingHelloResult>(sayingHelloJson);
        var actual = sayingHelloResult.Saying;

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
using SayingHelloLibrary.Domain;
using SayingHelloLibrary.JsonRpc;

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
    public async Task<JsonRpcResponse> Post()
    {
        Request.EnableBuffering();

        Request.Body.Position = 0;

        var json = await new StreamReader(Request.Body).ReadToEndAsync();

        return JsonRpcService.ProcessRequest(json, FunctionCalls.Dictionary);
    }
}
EOF

git add $FILE
git commit --message="Added saying hello controller."
git push --force

FILE=${PROJECT}/Properties/launchSettings.json

SERVER=$(jq '.profiles.http.applicationUrl' $FILE)

cd ..

FRAMEWORK=typescript-react
TEMPLATE=typescript

REPOSITORY=intrepion-$KEBOB-json-rpc-client-web-$FRAMEWORK-$TEMPLATE

# framework - the works
./intrepion-apps/new/common/type/full_stack/$FRAMEWORK/$TEMPLATE/the_works.sh $FRAMEWORK $REPOSITORY $TEMPLATE

# project - add saying hello
cd $REPOSITORY

FILE=src/App.tsx

sed -i '/import React from "react";/a\
import SayingHello from ".\/SayingHello";' $FILE
sed -i 's/  return <><\/>;/  return <SayingHello \/>;/' $FILE

npx prettier --write $FILE
git add $FILE

FILE=src/SayingHello.tsx

cat > $FILE << EOF
import * as React from "react";
import { useState } from "react";

const SERVER_URL = process.env.REACT_APP_SERVER_URL ?? "http://localhost:3000";

const SayingHello: React.FC = () => {
  const [name, setName] = useState("");
  const [message, setMessage] = useState("Hello, world!");

  const handleChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    setName(event.target.value);
  };

  const callEndpoint = () => {
    fetch(SERVER_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        id: "1",
        jsonrpc: "2.0",
        method: "say_hello",
        params: { name },
      }),
    })
      .then((response) => response.json())
      .then((responseJson) => {
        const result = responseJson.result;
        setMessage(result.saying);
      })
      .catch((error) => {
        console.error(error);
      });
  };

  return (
    <div>
      <input type="text" value={name} onChange={handleChange} />
      <button onClick={callEndpoint}>Call Endpoint</button>
      <div>{message}</div>
    </div>
  );
};

export default SayingHello;
EOF

npx prettier --write $FILE
git add $FILE

git commit --message "Added saying hello form."
git push --force

cd ..

CLIENT="http://localhost:3000"

# type - add run scripts
./intrepion-apps/new/common/type/full_stack/typescript-react-typescript-csharp-dotnet-webapi/add_run_scripts.sh $CLIENT $KEBOB $PROJECT $SERVER

popd

echo "Completed $SCRIPT"
