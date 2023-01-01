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

class AddResult
{
    public int Sum { get; set; }
}

public class JsonRpcTest
{
    [Fact]
    public void TestJsonRpc_HappyPath()
    {
        // Arrange
        AddResult Add(int a, int b)
        {
            return new AddResult
            {
                Sum = a + b
            };
        }

        var functions = new Dictionary<string, FunctionCall>
        {
            { "add", new FunctionCall
                {
                    Function = (List<Parameter> parameters) => Add((int)parameters.First(p => p.Name == "a").Value, (int)parameters.First(p => p.Name == "b").Value),
                    Parameters = new List<Parameter>
                    {
                        new Parameter { Name = "a", Kind = "int" },
                        new Parameter { Name = "b", Kind = "int" },
                    }
                }
            }
        };

        var json = \$\$\$"""{"id":"1","jsonrpc":"2.0","method":"add","params":{"a":1,"b":2}}""";

        // Act
        var response = JsonRpcService.ProcessRequest(json, functions);

        // Assert
        Assert.Null(response.Error);
        Assert.Equal("1", response.Id);
        Assert.Equal("2.0", response.JsonRpc);
        Assert.Equal(3, ((AddResult)response.Result).Sum);
    }

    [Fact]
    public void TestJsonRpc_ParseError()
    {
        // Arrange
        var functions = new Dictionary<string, FunctionCall> {};

        var json = \$\$\$"""{"id":"1","jsonrpc":"2.0","method":"add","params":{"a":1,"b":2}""";

        // Act
        var response = JsonRpcService.ProcessRequest(json, functions);

        // Assert
        Assert.Equal(-32700, response.Error.Code);
        Assert.Null(response.Error.Data);
        Assert.Equal("Parse error", response.Error.Message);
        Assert.Null(response.Id);
        Assert.Equal("2.0", response.JsonRpc);
        Assert.Null(response.Result);
    }

    [Fact]
    public void TestJsonRpc_InvalidRequest_WithEmptyString()
    {
        // Arrange
        var functions = new Dictionary<string, FunctionCall> {};

        var json = "";

        // Act
        var response = JsonRpcService.ProcessRequest(json, functions);

        // Assert
        Assert.Equal(-32600, response.Error.Code);
        Assert.Null(response.Error.Data);
        Assert.Equal("Invalid Request", response.Error.Message);
        Assert.Null(response.Id);
        Assert.Equal("2.0", response.JsonRpc);
        Assert.Null(response.Result);
    }

    [Fact]
    public void TestJsonRpc_InvalidRequest_WithInt()
    {
        // Arrange
        var functions = new Dictionary<string, FunctionCall> {};

        var json = "1";

        // Act
        var response = JsonRpcService.ProcessRequest(json, functions);

        // Assert
        Assert.Equal(-32600, response.Error.Code);
        Assert.Null(response.Error.Data);
        Assert.Equal("Invalid Request", response.Error.Message);
        Assert.Null(response.Id);
        Assert.Equal("2.0", response.JsonRpc);
        Assert.Null(response.Result);
    }

    [Fact]
    public void TestJsonRpc_InvalidRequest_WithDouble()
    {
        // Arrange
        var functions = new Dictionary<string, FunctionCall> {};

        var json = "3.0";

        // Act
        var response = JsonRpcService.ProcessRequest(json, functions);

        // Assert
        Assert.Equal(-32600, response.Error.Code);
        Assert.Null(response.Error.Data);
        Assert.Equal("Invalid Request", response.Error.Message);
        Assert.Null(response.Id);
        Assert.Equal("2.0", response.JsonRpc);
        Assert.Null(response.Result);
    }

    [Fact]
    public void TestJsonRpc_MethodNotFound()
    {
        // Arrange
        var functions = new Dictionary<string, FunctionCall> {};

        var json = \$\$\$"""{"id":"1","jsonrpc":"2.0","method":"add","params":{"a":1,"b":2}}""";

        // Act
        var response = JsonRpcService.ProcessRequest(json, functions);

        // Assert
        Assert.Equal(-32601, response.Error.Code);
        Assert.Null(response.Error.Data);
        Assert.Equal("Method not found", response.Error.Message);
        Assert.Null(response.Id);
        Assert.Equal("2.0", response.JsonRpc);
        Assert.Null(response.Result);
    }

    [Fact]
    public void TestJsonRpc_InvalidParams_ExpectingInt()
    {
        // Arrange
        AddResult Add(int a, int b)
        {
            return new AddResult
            {
                Sum = a + b
            };
        }

        var functions = new Dictionary<string, FunctionCall>
        {
            { "add", new FunctionCall
                {
                    Function = (List<Parameter> parameters) => Add((int)parameters.First(p => p.Name == "a").Value, (int)parameters.First(p => p.Name == "b").Value),
                    Parameters = new List<Parameter>
                    {
                        new Parameter { Name = "a", Kind = "int" },
                        new Parameter { Name = "b", Kind = "int" },
                    }
                }
            }
        };

        var json = \$\$\$"""{"id":"1","jsonrpc":"2.0","method":"add","params":{"a":1,"b":"2"}}""";

        // Act
        var response = JsonRpcService.ProcessRequest(json, functions);

        // Assert
        Assert.Equal(-32602, response.Error.Code);
        Assert.Null(response.Error.Data);
        Assert.Equal("Invalid params", response.Error.Message);
        Assert.Null(response.Id);
        Assert.Equal("2.0", response.JsonRpc);
        Assert.Null(response.Result);
    }

    [Fact]
    public void TestJsonRpc_InvalidParams_ExpectingString()
    {
        // Arrange
        AddResult Add(int a, int b)
        {
            return new AddResult
            {
                Sum = a + b
            };
        }

        var functions = new Dictionary<string, FunctionCall>
        {
            { "add", new FunctionCall
                {
                    Function = (List<Parameter> parameters) => Add((int)parameters.First(p => p.Name == "a").Value, (int)parameters.First(p => p.Name == "b").Value),
                    Parameters = new List<Parameter>
                    {
                        new Parameter { Name = "a", Kind = "int" },
                        new Parameter { Name = "b", Kind = "string" },
                    }
                }
            }
        };

        var json = \$\$\$"""{"id":"1","jsonrpc":"2.0","method":"add","params":{"a":1,"b":2}}""";

        // Act
        var response = JsonRpcService.ProcessRequest(json, functions);

        // Assert
        Assert.Equal(-32602, response.Error.Code);
        Assert.Null(response.Error.Data);
        Assert.Equal("Invalid params", response.Error.Message);
        Assert.Null(response.Id);
        Assert.Equal("2.0", response.JsonRpc);
        Assert.Null(response.Result);
    }

    [Fact]
    public void TestJsonRpc_InvalidParams_EmptyParam()
    {
        // Arrange
        AddResult Add(int a, int b)
        {
            return new AddResult
            {
                Sum = a + b
            };
        }

        var functions = new Dictionary<string, FunctionCall>
        {
            { "add", new FunctionCall
                {
                    Function = (List<Parameter> parameters) => Add((int)parameters.First(p => p.Name == "a").Value, (int)parameters.First(p => p.Name == "b").Value),
                    Parameters = new List<Parameter>
                    {
                        new Parameter { Name = "a", Kind = "int" },
                        new Parameter { Name = "b", Kind = "int" },
                    }
                }
            }
        };

        var json = \$\$\$"""{"id":"1","jsonrpc":"2.0","method":"add","params":{"a":1,"b":null}}""";

        // Act
        var response = JsonRpcService.ProcessRequest(json, functions);

        // Assert
        Assert.Equal(-32602, response.Error.Code);
        Assert.Null(response.Error.Data);
        Assert.Equal("Invalid params", response.Error.Message);
        Assert.Null(response.Id);
        Assert.Equal("2.0", response.JsonRpc);
        Assert.Null(response.Result);
    }

    [Fact]
    public void TestJsonRpc_InvalidParams_MissingParam()
    {
        // Arrange
        AddResult Add(int a, int b)
        {
            return new AddResult
            {
                Sum = a + b
            };
        }

        var functions = new Dictionary<string, FunctionCall>
        {
            { "add", new FunctionCall
                {
                    Function = (List<Parameter> parameters) => Add((int)parameters.First(p => p.Name == "a").Value, (int)parameters.First(p => p.Name == "b").Value),
                    Parameters = new List<Parameter>
                    {
                        new Parameter { Name = "a", Kind = "int" },
                        new Parameter { Name = "b", Kind = "int" },
                    }
                }
            }
        };

        var json = \$\$\$"""{"id":"1","jsonrpc":"2.0","method":"add","params":{"a":1}}""";

        // Act
        var response = JsonRpcService.ProcessRequest(json, functions);

        // Assert
        Assert.Equal(-32602, response.Error.Code);
        Assert.Null(response.Error.Data);
        Assert.Equal("Invalid params", response.Error.Message);
        Assert.Null(response.Id);
        Assert.Equal("2.0", response.JsonRpc);
        Assert.Null(response.Result);
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
using System.Text.Json;
using System.Text.Json.Serialization;

namespace ${PASCAL}Library.JsonRpc;

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

FILE=${PASCAL}Library/JsonRpc/JsonRpcResponse.cs

cat > $FILE << EOF
using System.Text.Json.Serialization;

namespace ${PASCAL}Library.JsonRpc;

public class JsonRpcResponse
{
    [JsonPropertyName("id")]
    public string Id { get; set; }

    [JsonPropertyName("jsonrpc")]
    public string JsonRpc { get; set; }

    [JsonPropertyName("result")]
    public object Result { get; set; }

    [JsonPropertyName("error")]
    public JsonRpcError Error { get; set; }
}
EOF

git add $FILE

FILE=${PASCAL}Library/JsonRpc/JsonRpcService.cs

cat > $FILE << EOF
using System.Text.Json;

namespace ${PASCAL}Library.JsonRpc;

public static class JsonRpcService
{
    public static JsonRpcResponse ProcessRequest(string json, Dictionary<string, FunctionCall> functionCalls)
    {
        if (string.IsNullOrEmpty(json) || double.TryParse(json, out _))
        {
            return new JsonRpcResponse
            {
                JsonRpc = "2.0",
                Error = new JsonRpcError
                {
                    Code = -32600,
                    Message = "Invalid Request"
                }
            };
        }
        try {
            var request = JsonSerializer.Deserialize<JsonRpcRequest>(json);

            if (request == null || string.IsNullOrEmpty(request.Method) || !functionCalls.ContainsKey(request.Method))
            {
                return new JsonRpcResponse
                {
                    JsonRpc = "2.0",
                    Error = new JsonRpcError
                    {
                        Code = -32601,
                        Message = "Method not found"
                    }
                };
            }

            FunctionCall functionCall = functionCalls[request.Method];

            JsonElement paramsElement = request.Params;
            if (paramsElement.ValueKind == JsonValueKind.Object)
            {
                foreach (var property in paramsElement.EnumerateObject())
                {
                    if (property.Value.ValueKind == JsonValueKind.Null)
                    {
                        return new JsonRpcResponse
                        {
                            JsonRpc = "2.0",
                            Error = new JsonRpcError
                            {
                                Code = -32602,
                                Message = "Invalid params"
                            }
                        };
                    }
                    var parameter = functionCall.Parameters.First(p => p.Name == property.Name);
                    try {
                        switch (parameter.Kind)
                        {
                            case "int":
                                parameter.Value = property.Value.GetInt32();
                                break;
                            case "string":
                                parameter.Value = property.Value.GetString();
                                break;
                            default:
                                break;
                        }
                    } catch (InvalidOperationException) {
                        return new JsonRpcResponse
                        {
                            JsonRpc = "2.0",
                            Error = new JsonRpcError
                            {
                                Code = -32602,
                                Message = "Invalid params"
                            }
                        };
                    }
                }
            }

            var result = functionCall.Function(functionCall.Parameters);

            return new JsonRpcResponse
            {
                JsonRpc = "2.0",
                Result = result,
                Id = request.Id
            };
        } catch (JsonException) {
            return new JsonRpcResponse
            {
                JsonRpc = "2.0",
                Error = new JsonRpcError
                {
                    Code = -32700,
                    Message = "Parse error"
                }
            };
        } catch (NullReferenceException) {
            return new JsonRpcResponse
            {
                JsonRpc = "2.0",
                Error = new JsonRpcError
                {
                    Code = -32602,
                    Message = "Invalid params"
                }
            };
        }

    }
}
EOF

git add $FILE

FILE=${PASCAL}Library/JsonRpc/Parameter.cs

cat > $FILE << EOF
namespace ${PASCAL}Library.JsonRpc;

public class Parameter
{
    public string Kind { get; set; }
    public string Name { get; set; }
    public object Value { get; set; }
}
EOF

git add $FILE

git commit --message="Added JSON-RPC code."

popd

echo "Completed $SCRIPT $PASCAL $REPOSITORY"