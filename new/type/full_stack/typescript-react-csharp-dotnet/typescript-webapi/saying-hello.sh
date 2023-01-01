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

public class JsonRpcTest
{
    [Fact]
    public void TestJsonRpc()
    {
        // Define the functions dictionary
        Dictionary<string, FunctionCall> functions = new Dictionary<string, FunctionCall>
        {
            { "say_hello", new FunctionCall
                {
                    Function = (List<Parameter> parameters) => SayingHello.SayHello((string)parameters.First(p => p.Name == "name").Value),
                    Parameters = new List<Parameter>
                    {
                        new Parameter { Name = "name" },
                    }
                }
            }
        };

        // Define the request JSON string
        string json = \$\$$"""{"id":"1","jsonrpc":"2.0","method":"say_hello","params":{"name":"Oliver"}}""";

        // Call ProcessRequest and get the response
        JsonRpcResponse response = JsonRpcService.ProcessRequest(json, functions);

        // Assert that the response is correct
        Assert.Equal("2.0", response.JsonRpc);
        Assert.Equal("1", response.Id);
        Assert.Equal("Hello, Oliver!", ((SayingHelloResult)response.Result).Saying);
    }
}
EOF

git add $FILE
git commit --message="Added json-rpc tests."

mkdir -p SayingHelloLibrary/JsonRpc

FILE=SayingHelloLibrary/JsonRpc/FunctionCall.cs

cat > $FILE << EOF
namespace SayingHelloLibrary.JsonRpc;

public class FunctionCall
{
    public Func<List<Parameter>, object> Function { get; set; }
    public List<Parameter> Parameters { get; set; }
}
EOF

git add $FILE

FILE=SayingHelloLibrary/JsonRpc/JsonRpcError.cs

cat > $FILE << EOF
using System.Text.Json.Serialization;

namespace SayingHelloLibrary.JsonRpc;

public class JsonRpcError
{
    [JsonPropertyName("code")]
    public int Code { get; set; }

    [JsonPropertyName("data")]
    public object Data { get; set; }

    [JsonPropertyName("message")]
    public string Message { get; set; }
}
EOF

git add $FILE

FILE=SayingHelloLibrary/JsonRpc/JsonRpcRequest.cs

cat > $FILE << EOF
using System.Text.Json;
using System.Text.Json.Serialization;

namespace SayingHelloLibrary.JsonRpc;

public class JsonRpcRequest
{
    [JsonPropertyName("id")]
    public string Id { get; set; }

    [JsonPropertyName("jsonrpc")]
    public string JsonRpc { get; set; }

    [JsonPropertyName("method")]
    public string Method { get; set; }

    [JsonPropertyName("params")]
    public JsonElement Params { get; set; }
}
EOF

git add $FILE

FILE=SayingHelloLibrary/JsonRpc/JsonRpcResponse.cs

cat > $FILE << EOF
using System.Text.Json.Serialization;

namespace SayingHelloLibrary.JsonRpc;

public class JsonRpcResponse
{
    [JsonPropertyName("error")]
    public JsonRpcError Error { get; set; }

    [JsonPropertyName("id")]
    public string Id { get; set; }

    [JsonPropertyName("jsonrpc")]
    public string JsonRpc { get; set; }

    [JsonPropertyName("result")]
    public object Result { get; set; }
}
EOF

git add $FILE

FILE=SayingHelloLibrary/JsonRpc/JsonRpcService.cs

cat > $FILE << EOF
using System.Text.Json;

namespace SayingHelloLibrary.JsonRpc;

public static class JsonRpcService
{
    public static JsonRpcResponse ProcessRequest(string json, Dictionary<string, FunctionCall> functions)
    {
        // Deserialize the JSON string to a JsonRpcRequest object
        var request = JsonSerializer.Deserialize<JsonRpcRequest>(json);

        // Get the function and parameters from the dictionary
        FunctionCall functionCall = functions[request.Method];

        // Set the values of the parameters based on the request's params object
        JsonElement paramsElement = request.Params;
        if (paramsElement.ValueKind == JsonValueKind.Object)
        {
            foreach (var property in paramsElement.EnumerateObject())
            {
                functionCall.Parameters.First(p => p.Name == property.Name).Value = property.Value.GetString();
            }
        }

        // Call the function and get the result
        var result = functionCall.Function(functionCall.Parameters);

        // Return a JsonRpcResponse with the result
        return new JsonRpcResponse
        {
            JsonRpc = "2.0",
            Result = result,
            Id = request.Id
        };
    }
}
EOF

git add $FILE

FILE=SayingHelloLibrary/JsonRpc/Parameter.cs

cat > $FILE << EOF
namespace SayingHelloLibrary.JsonRpc;

public class Parameter
{
    public string Name { get; set; }
    public object Value { get; set; }
}
EOF

git add $FILE

git commit --message="Added json-rpc code."

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
    [InlineData(\$\$$"""{"id":"1","jsonrpc":"2.0","params":{"name":"Oliver"}}""", \$\$$"""{"id":"1","jsonrpc":"2.0","result":{"saying":"Hello, Oliver!"}}""")]
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
        return \$\$$"""{"id":"1","jsonrpc":"2.0","result":{"saying":"Hello, Oliver!"}}""";
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
