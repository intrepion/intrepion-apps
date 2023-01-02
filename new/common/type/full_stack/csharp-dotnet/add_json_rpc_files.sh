#!/usr/bin/env bash

SCRIPT=$0
PASCAL=$1
REPOSITORY=$2

echo "Running $SCRIPT $PASCAL $REPOSITORY"

pushd .

cd $REPOSITORY
pwd

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
