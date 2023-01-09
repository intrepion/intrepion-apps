#!/usr/bin/env bash

SCRIPT=$0
PASCAL=$1
REPOSITORY=$2

echo " - Running $SCRIPT $PASCAL $REPOSITORY"

if [ $# -ne 2 ]; then
  echo "usage: $SCRIPT <PASCAL> <REPOSITORY>"
  exit 1
fi

pushd .

cd $REPOSITORY
pwd

mkdir -p ${PASCAL}JsonRpc/JsonRpc

FILE=${PASCAL}JsonRpc/JsonRpc/JsonRpcError.cs
cat > $FILE << EOF
using System.Text.Json.Serialization;

namespace ${PASCAL}JsonRpc.JsonRpc;

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

FILE=${PASCAL}JsonRpc/JsonRpc/JsonRpcRequest.cs
cat > $FILE << EOF
using System.Text.Json;
using System.Text.Json.Serialization;

namespace ${PASCAL}JsonRpc.JsonRpc;

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

FILE=${PASCAL}JsonRpc/JsonRpc/JsonRpcResponse.cs
cat > $FILE << EOF
using System.Text.Json.Serialization;

namespace ${PASCAL}JsonRpc.JsonRpc;

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

echo " - Completed $SCRIPT $PASCAL $REPOSITORY"
