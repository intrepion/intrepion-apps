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
pwd

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
        var actual = SayingHello.SayHello(name);

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
        var actual = SayingHello.SayHello(name);

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

FILE=SayingHelloWebApi/Controllers/SayingHelloController.cs

cat > $FILE << EOF
using Microsoft.AspNetCore.Mvc;
using SayingHelloLibrary.JsonRpc;
using SayingHelloWebApi.Data;
using SayingHelloWebApi.JsonRpc;

namespace SayingHelloWebApi.Controllers;

[ApiController]
[Route("/")]
public class SayingHelloController : ControllerBase
{
    private readonly AppDBContext _context;
    private readonly ILogger<SayingHelloController> _logger;

    public SayingHelloController(AppDBContext context, ILogger<SayingHelloController> logger)
    {
        _context = context;
        _logger = logger;
    }

    [HttpPost(Name = "PostSayingHello")]
    public async Task<JsonRpcResponse> Post()
    {
        Request.EnableBuffering();

        Request.Body.Position = 0;

        var json = await new StreamReader(Request.Body).ReadToEndAsync();

        return await JsonRpcService.ProcessRequest(json, FunctionCalls.Dictionary, _context);
    }
}
EOF

git add $FILE
git commit --message="Added saying hello controller."

mkdir -p SayingHelloWebApi/Data

FILE=SayingHelloWebApi/Data/AppDBContext.cs

cat > $FILE << EOF
using Microsoft.EntityFrameworkCore;
using SayingHelloWebApi.Entities;

namespace SayingHelloWebApi.Data;

public class AppDBContext : DbContext
{
    public AppDBContext(DbContextOptions<AppDBContext> options) : base(options)
    {
        Database.EnsureCreated();
        DBInitializer.Initialize(this);
    }

    protected override void OnModelCreating(ModelBuilder builder)
    {
        builder.Entity<Greeting>()
            .HasIndex(greeting => greeting.Name)
            .IsUnique();
    }
    public DbSet<Greeting> Greetings { get; set; }
}
EOF

git add $FILE

FILE=SayingHelloWebApi/Data/DBInitializer.cs

cat > $FILE << EOF
using SayingHelloWebApi.Entities;

namespace SayingHelloWebApi.Data;

public static class DBInitializer
{
    public static void Initialize(AppDBContext context)
    {
        if (context.Greetings.Any())
        {
            return;
        }

        var greetings = new Greeting[]
        {
            new Greeting
            {
                Message = "Hello, world!",
                Name = "",
            },
            new Greeting
            {
                Message = "Hello, Oliver!",
                Name = "Oliver",
            },
            new Greeting
            {
                Message = "Hello, James!",
                Name = "James",
            },
        };

        context.Greetings.AddRange(greetings);
        context.SaveChanges();
    }
}
EOF

git add $FILE
git commit --message="Added data files."

mkdir -p SayingHelloWebApi/Entities

FILE=SayingHelloWebApi/Entities/Greeting.cs

cat > $FILE << EOF
using System.Text.Json.Serialization;

namespace SayingHelloWebApi.Entities;

public class Greeting
{
    [JsonPropertyName("id")]
    public Guid Id { get; set; }

    [JsonPropertyName("name")]
    public string Name { get; set; }

    [JsonPropertyName("message")]
    public string Message { get; set; }
}
EOF

git add $FILE
git commit --message="Added entities."

mkdir -p SayingHelloWebApi/JsonRpc

FILE=SayingHelloWebApi/JsonRpc/FunctionCall.cs

cat > $FILE << EOF
namespace SayingHelloWebApi.JsonRpc;

public class FunctionCall
{
    public List<Parameter> Parameters { get; set; }
}
EOF

git add $FILE

FILE=SayingHelloWebApi/JsonRpc/FunctionCalls.cs

cat > $FILE << EOF
namespace SayingHelloWebApi.JsonRpc;

public static class FunctionCalls
{
    public static Dictionary<string, FunctionCall> Dictionary = new Dictionary<string, FunctionCall>
    {
        {
            "new_greeting", new FunctionCall
            {
                Parameters = new List<Parameter>
                {
                    new Parameter { Name = "name", Kind = "string" },
                }
            }
        },
        {
            "get_all_greetings", new FunctionCall
            {
                Parameters = new List<Parameter> {}
            }
        },
    };
}
EOF

git add $FILE

FILE=SayingHelloWebApi/JsonRpc/JsonRpcService.cs

cat > $FILE << EOF
using SayingHelloLibrary.JsonRpc;
using SayingHelloWebApi.Data;
using SayingHelloWebApi.Repositories;
using System.Text.Json;

namespace SayingHelloWebApi.JsonRpc;

public static class JsonRpcService
{
    public static async Task<JsonRpcResponse> ProcessRequest(string json, Dictionary<string, FunctionCall> functionCalls, AppDBContext context)
    {
        if (string.IsNullOrEmpty(json) || double.TryParse(json, out _))
        {
            return new JsonRpcResponse
            {
                JsonRpc = "2.0",
                Error = new JsonRpcError
                {
                    Code = -32600,
                    Message = "Invalid Request - json is not found"
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

            if (functionCall.Parameters.Count > 0)
            {
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
                                    Message = "Invalid params - value is null"
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
                                    Message = "Invalid params - value is not of the correct type"
                                }
                            };
                        }
                    }
                }
            }

            if (request.Method == "new_greeting") {
                var name = functionCall.Parameters.First(p => p.Name == "name").Value.ToString();
                var result = await GreetingRepository.NewGreetingAsync(context, name);

                return new JsonRpcResponse
                {
                    JsonRpc = "2.0",
                    Result = result,
                    Id = request.Id
                };
            } else if (request.Method == "get_all_greetings") {
                var result = await GreetingRepository.GetAllGreetingsAsync(context);

                return new JsonRpcResponse
                {
                    JsonRpc = "2.0",
                    Result = result,
                    Id = request.Id
                };
            }

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
        } catch (Exception) {
            return new JsonRpcResponse
            {
                JsonRpc = "2.0",
                Error = new JsonRpcError
                {
                    Code = -32602,
                    Message = "Invalid Request - internal error"
                }
            };
        }

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
}
EOF

git add $FILE

FILE=SayingHelloWebApi/JsonRpc/Parameter.cs

cat > $FILE << EOF
namespace SayingHelloWebApi.JsonRpc;

public class Parameter
{
    public string Kind { get; set; }
    public string Name { get; set; }
    public object Value { get; set; }
}
EOF

git add $FILE
git commit --message="Added project json rpc files."

mkdir -p SayingHelloWebApi/Repositories

FILE=SayingHelloWebApi/Repositories/GreetingRepository.cs

cat > $FILE << EOF
using Microsoft.EntityFrameworkCore;
using SayingHelloLibrary.Domain;
using SayingHelloWebApi.Data;
using SayingHelloWebApi.Entities;
using SayingHelloWebApi.Results;

namespace SayingHelloWebApi.Repositories;

public static class GreetingRepository
{
    public static async Task<GetAllGreetingsResult> GetAllGreetingsAsync(AppDBContext context)
    {
        var greetings = await context.Greetings.ToListAsync();

        return new GetAllGreetingsResult
        {
            Greetings = greetings
        };
    }

    public static async Task<NewGreetingResult> NewGreetingAsync(AppDBContext context, string name)
    {
        name = name.Trim();

        var greeting = await context.Greetings.Where(greeting => greeting.Name == name).FirstOrDefaultAsync();
        if (greeting != null) {
            return new NewGreetingResult
            {
                Message = greeting.Message
            };
        }

        var message = SayingHello.SayHello(name);

        greeting = new Greeting
        {
            Name = name,
            Message = message,
        };

        await context.AddAsync(greeting);
        context.SaveChanges();

        return new NewGreetingResult
        {
            Message = message
        };
    }
}
EOF

git add $FILE
git commit --message="Added repository files."

mkdir -p SayingHelloWebApi/Results

FILE=SayingHelloWebApi/Results/GetAllGreetingsResult.cs

cat > $FILE << EOF
using System.Text.Json.Serialization;
using SayingHelloWebApi.Entities;

namespace SayingHelloWebApi.Results;

public class GetAllGreetingsResult
{
    [JsonPropertyName("greetings")]
    public List<Greeting> Greetings { get; set; }
}
EOF

git add $FILE

FILE=SayingHelloWebApi/Results/NewGreetingResult.cs

cat > $FILE << EOF
using System.Text.Json.Serialization;

namespace SayingHelloWebApi.Results;

public class NewGreetingResult
{
    [JsonPropertyName("message")]
    public string Message { get; set; }
}
EOF

git add $FILE
git commit --message="Added result files."

git push --force

FILE=SayingHelloWebApi/Properties/launchSettings.json

SERVER=$(jq '.profiles.http.applicationUrl' $FILE)

cd ..

FRAMEWORK=typescript-react
TEMPLATE=typescript

REPOSITORY=intrepion-$KEBOB-json-rpc-client-web-$FRAMEWORK-$TEMPLATE

# framework - the works
./intrepion-apps/new/common/type/full_stack/$FRAMEWORK/$TEMPLATE/the_works.sh $FRAMEWORK $REPOSITORY $TEMPLATE

# project - add saying hello
cd $REPOSITORY
pwd

FILE=src/components/Home.tsx

cat > $FILE << EOF
import React from "react";
import SayingHello from "./SayingHello";

const Home = () => {
  return (
    <>
      <p>Home</p>
      <SayingHello />
    </>
  );
};

export default Home;
EOF

git add $FILE

FILE=src/components/SayingHello.tsx

cat > $FILE << EOF
import React, { useEffect, useState } from "react";
import Greeting from "./Greeting";

const SERVER_URL = process.env.REACT_APP_SERVER_URL ?? "http://localhost:3000";

type GreetingType = {
  id: string;
  message: string;
  name: string;
};

const SayingHello: React.FC = () => {
  const [greetings, setGreetings] = useState<GreetingType[]>([]);
  const [name, setName] = useState("");
  const [message, setMessage] = useState("Hello, world!");

  useEffect(() => {
    fetch(SERVER_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        id: "1",
        jsonrpc: "2.0",
        method: "get_all_greetings",
      }),
    })
      .then((response) => response.json())
      .then((responseJson) => {
        if (responseJson.result) {
          const result = responseJson.result;
          setGreetings(result.greetings);
        } else if (responseJson.error) {
          console.error(responseJson.error);
        }
      })
      .catch((error) => {
        console.error(error);
      });
  }, [message]);

  const handleChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    setName(event.target.value);
  };

  const callSayHello = (event: React.MouseEvent<HTMLElement>) => {
    event.preventDefault();
    fetch(SERVER_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        id: "1",
        jsonrpc: "2.0",
        method: "new_greeting",
        params: { name },
      }),
    })
      .then((response) => response.json())
      .then((responseJson) => {
        const result = responseJson.result;
        setMessage(result.message);
      })
      .catch((error) => {
        console.error(error);
      });
  };

  return (
    <div>
      <input type="text" value={name} onChange={handleChange} />
      <button onClick={callSayHello}>Say Hello</button>
      <div>{message}</div>
      <p>Previous Greetings</p>
      <ul>
        {greetings.map((greeting) => (
          <li key={greeting.id}>
            <Greeting
              id={greeting.id}
              message={greeting.message}
              name={greeting.name}
            />
          </li>
        ))}
      </ul>
    </div>
  );
};

export default SayingHello;
EOF

git add $FILE

FILE=src/components/Greeting.tsx

cat > $FILE << EOF
import React from "react";

interface GreetingInterface {
  id: string;
  message: string;
  name: string;
}

const Greeting = (props: GreetingInterface) => {
  const { id, name, message } = props;

  return (
    <>
      {id}: {name}, {message}
    </>
  );
};

export default Greeting;
EOF

npx prettier --write .
git commit --message "Added saying hello form."
git push --force

cd ..

CLIENT="http://localhost:3000"

# type - add run scripts
./intrepion-apps/new/common/type/full_stack/typescript-react-typescript-csharp-dotnet-webapi/add_run_scripts.sh $CLIENT $KEBOB $PROJECT $SERVER

popd

echo "Completed $SCRIPT"
