#!/usr/bin/env bash

SCRIPT=$0
PASCAL=$1
REPOSITORY=$2

echo "Running $SCRIPT $PASCAL $REPOSITORY"

pushd .

cd $REPOSITORY

mkdir -p ${PASCAL}Tests/JsonRpc

FILE=${PASCAL}Tests/JsonRpc/JsonRpcTest.cs

cat > $FILE << EOF
using ${PASCAL}Library.JsonRpc;

namespace ${PASCAL}Tests.JsonRpc;

public class JsonRpcTest
{
    [Fact]
    public void TestJsonRpc()
    {
        // Define the Add function
        int Add(int a, int b)
        {
            return a + b;
        }

        // Define the functions dictionary
        Dictionary<string, FunctionCall> functions = new Dictionary<string, FunctionCall>
        {
            { "add", new FunctionCall
                {
                    Function = (List<Parameter> parameters) => Add((int)parameters.First(p => p.Name == "a").Value, (int)parameters.First(p => p.Name == "b").Value),
                    Parameters = new List<Parameter>
                    {
                        new Parameter { Name = "a" },
                        new Parameter { Name = "b" }
                    }
                }
            }
        };

        // Define the request JSON string
        string json = \$\$$"""{"id":1,"jsonrpc":"2.0","method":"add","params":{"a":1,"b":2}}""";

        // Call ProcessRequest and get the response
        var response = JsonRpcService.ProcessRequest(json, functions);

        // Assert that the response is correct
        Assert.Null(response.Error);
        Assert.Equal(1, response.Id);
        Assert.Equal("2.0", response.JsonRpc);
        Assert.Equal(3, response.Result);
    }
}
EOF

git add $FILE
git commit --message="Added JSON-RPC tests."

mkdir -p ${PASCAL}Library/JsonRpc

FILE=${PASCAL}Library/JsonRpc/FunctionCall.cs

cat > $FILE << EOF
namespace ${PASCAL}Library.JsonRpc;

public class FunctionCall
{
    public Func<List<Parameter>, object> Function { get; set; }
    public List<Parameter> Parameters { get; set; }
}
EOF

git add $FILE

FILE=${PASCAL}Library/JsonRpc/JsonRpcError.cs

cat > $FILE << EOF
using System.Text.Json.Serialization;

namespace ${PASCAL}Library.JsonRpc;

public class JsonRpcError
{
    [JsonPropertyName("code")]
    public int Code { get; set; }

    [JsonPropertyName("message")]
    public string Message { get; set; }

    [JsonPropertyName("data")]
    public object Data { get; set; }
}
EOF

git add $FILE

FILE=${PASCAL}Library/JsonRpc/JsonRpcRequest.cs

cat > $FILE << EOF
using System.Text.Json.Serialization;

namespace ${PASCAL}Library.JsonRpc;

public class JsonRpcRequest
{
    [JsonPropertyName("jsonrpc")]
    public string JsonRpc { get; set; }

    [JsonPropertyName("method")]
    public string Method { get; set; }

    [JsonPropertyName("params")]
    public object[] Params { get; set; }

    [JsonPropertyName("id")]
    public object Id { get; set; }
}
EOF

git add $FILE

FILE=${PASCAL}Library/JsonRpc/JsonRpcResponse.cs

cat > $FILE << EOF
using System.Text.Json.Serialization;

namespace ${PASCAL}Library.JsonRpc;

public class JsonRpcResponse
{
    [JsonPropertyName("jsonrpc")]
    public string JsonRpc { get; set; }

    [JsonPropertyName("result")]
    public object Result { get; set; }

    [JsonPropertyName("error")]
    public JsonRpcError Error { get; set; }

    [JsonPropertyName("id")]
    public object Id { get; set; }
}
EOF

git add $FILE

FILE=${PASCAL}Library/JsonRpc/JsonRpcService.cs

cat > $FILE << EOF
using System.Text.Json;

namespace ${PASCAL}Library.JsonRpc;

public static class JsonRpcService
{
    public static JsonRpcResponse ProcessRequest(string json, Dictionary<string, FunctionCall> functions)
    {
        // Parse the JSON string
        var request = JsonSerializer.Deserialize<JsonRpcRequest>(json);

        // Get the function call
        var functionCall = functions[request.Method];

        // Call the function
        var result = functionCall.Function(functionCall.Parameters);

        // Return the response
        return new JsonRpcResponse
        {
            Id = request.Id,
            JsonRpc = request.JsonRpc,
            Result = result
        };
    }
}
EOF

git add $FILE

FILE=${PASCAL}Library/JsonRpc/Parameter.cs

cat > $FILE << EOF
namespace ${PASCAL}Library.JsonRpc;

public class Parameter
{
    public string Name { get; set; }
    public object Value { get; set; }
}
EOF

git add $FILE

git commit --message="Added JSON-RPC code."

popd

echo "Completed $SCRIPT $PASCAL $REPOSITORY"
