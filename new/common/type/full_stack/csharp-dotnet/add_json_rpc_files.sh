#!/usr/bin/env bash

SCRIPT=$0
REPOSITORY=$1

echo " - Running $SCRIPT $REPOSITORY"

if [ $# -ne 1 ]; then
  echo "usage: $SCRIPT <REPOSITORY>"
  exit 1
fi

pushd .

cd $REPOSITORY
pwd

FILE=JsonRpc/JsonRpcError.cs
cat > $FILE << EOF
using System.Text.Json.Serialization;

namespace JsonRpc;

public class JsonRpcError
{
    [JsonPropertyName("code")]
    public int? Code { get; set; }

    [JsonPropertyName("message")]
    public string? Message { get; set; }

    [JsonPropertyName("data")]
    public object? Data { get; set; }
}
EOF
git add $FILE

FILE=JsonRpc/JsonRpcRequest.cs
cat > $FILE << EOF
using System.Text.Json;
using System.Text.Json.Serialization;

namespace JsonRpc;

public class JsonRpcRequest
{
    [JsonPropertyName("id")]
    public string? Id { get; set; }

    [JsonPropertyName("jsonrpc")]
    public string? JsonRpc { get; set; }

    [JsonPropertyName("method")]
    public string? Method { get; set; }

    [JsonPropertyName("params")]
    public JsonElement? Params { get; set; }
}
EOF
git add $FILE

FILE=JsonRpc/JsonRpcResponse.cs
cat > $FILE << EOF
using System.Text.Json.Serialization;

namespace JsonRpc;

public class JsonRpcResponse
{
    [JsonPropertyName("id")]
    public string? Id { get; set; }

    [JsonPropertyName("jsonrpc")]
    public string? JsonRpc { get; set; }

    [JsonPropertyName("result")]
    public object? Result { get; set; }

    [JsonPropertyName("error")]
    public JsonRpcError? Error { get; set; }
}
EOF
git add $FILE

git commit --message="Added JSON-RPC code."

popd

echo " - Completed $SCRIPT $REPOSITORY"
