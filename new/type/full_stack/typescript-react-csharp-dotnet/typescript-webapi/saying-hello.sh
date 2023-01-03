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

FILE=SayingHelloWebApi/appsettings.Development.json

cat > $FILE << EOF
{
  "ConnectionStrings": {  
    "DefaultConnection": "Host=localhost;Port=5432;Database=intrepion;Username=postgres;Password=password;SSL Mode=Disable;Trust Server Certificate=true;"
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  }
}
EOF

git add $FILE
git commit --message "Updated app settings."

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
    private readonly ApplicationDbContext _context;
    private readonly ILogger<SayingHelloController> _logger;

    public SayingHelloController(ApplicationDbContext context, ILogger<SayingHelloController> logger)
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

FILE=SayingHelloWebApi/Data/ApplicationDbContext.cs

cat > $FILE << EOF
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using SayingHelloWebApi.Entities;

namespace SayingHelloWebApi.Data;

public class ApplicationDbContext : IdentityDbContext<User, Role, Guid>
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : base(options)
    {
        Database.EnsureCreated();
        DBInitializer.Initialize(this);
    }

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);

        builder.Entity<Greeting>(greeting => {
            greeting.HasIndex(g => g.Name).IsUnique();
        });
    }

    public DbSet<Greeting> Greetings { get; set; }
    public DbSet<Role> Roles { get; set; }
    public DbSet<User> Users { get; set; }
}
EOF

git add $FILE

FILE=SayingHelloWebApi/Data/DBInitializer.cs

cat > $FILE << EOF
using SayingHelloWebApi.Entities;

namespace SayingHelloWebApi.Data;

public static class DBInitializer
{
    public static void Initialize(ApplicationDbContext context)
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

FILE=SayingHelloWebApi/Entities/Role.cs

cat > $FILE << EOF
using Microsoft.AspNetCore.Identity;
using System.Text.Json.Serialization;

namespace SayingHelloWebApi.Entities;

public class Role : IdentityRole<Guid>
{
    [JsonPropertyName("id")]
    public Guid Id { get; set; }

    [JsonPropertyName("name")]
    public string Name { get; set; }
}
EOF

git add $FILE

FILE=SayingHelloWebApi/Entities/User.cs

cat > $FILE << EOF
using Microsoft.AspNetCore.Identity;
using System.Text.Json.Serialization;

namespace SayingHelloWebApi.Entities;

public class User : IdentityUser<Guid>
{
    [JsonPropertyName("id")]
    public Guid Id { get; set; }

    [JsonPropertyName("email")]
    public string Email { get; set; }

    [JsonPropertyName("email_verified")]
    public string EmailVerified { get; set; }

    [JsonPropertyName("password")]
    public string Password { get; set; }

    [JsonPropertyName("password_verified")]
    public string PasswordVerified { get; set; }

    [JsonPropertyName("registered_when")]
    public DateTime RegisteredWhen { get; set; }

    [JsonPropertyName("username")]
    public string Username { get; set; }

    [JsonPropertyName("verify_email")]
    public string VerifyEmail { get; set; }

    [JsonPropertyName("verify_email_expiration")]
    public DateTime VerifyEmailExpiration { get; set; }

    [JsonPropertyName("verify_password")]
    public string VerifyPassword { get; set; }

    [JsonPropertyName("verify_password_expiration")]
    public DateTime VerifyPasswordExpiration { get; set; }
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
            "get_all_greetings", new FunctionCall
            {
                Parameters = new List<Parameter> {}
            }
        },
        {
            "login", new FunctionCall
            {
                Parameters = new List<Parameter>
                {
                    new Parameter { Name = "password", Kind = "string" },
                    new Parameter { Name = "username", Kind = "string" },
                }
            }
        },
        {
            "logout", new FunctionCall
            {
                Parameters = new List<Parameter> {}
            }
        },
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
            "register", new FunctionCall
            {
                Parameters = new List<Parameter>
                {
                    new Parameter { Name = "confirm", Kind = "string" },
                    new Parameter { Name = "email", Kind = "string" },
                    new Parameter { Name = "password", Kind = "string" },
                    new Parameter { Name = "username", Kind = "string" },
                }
            }
        }
    };
}
EOF

git add $FILE

FILE=SayingHelloWebApi/JsonRpc/JsonRpcService.cs

cat > $FILE << EOF
using SayingHelloLibrary.JsonRpc;
using SayingHelloWebApi.Data;
using SayingHelloWebApi.Params;
using SayingHelloWebApi.Repositories;
using System.Text.Json;

namespace SayingHelloWebApi.JsonRpc;

public static class JsonRpcService
{
    public static async Task<JsonRpcResponse> ProcessRequest(string json, Dictionary<string, FunctionCall> functionCalls, ApplicationDbContext context)
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

            if (request.Method == "get_all_greetings") {
                return await GreetingRepository.GetAllGreetingsAsync(context, request);
            } else if (request.Method == "login") {
                return await UserRepository.LoginAsync(context, request);
            } else if (request.Method == "logout") {
                return await UserRepository.LogoutAsync(context, request);
            } else if (request.Method == "new_greeting") {
                return await GreetingRepository.NewGreetingAsync(context, request);
            } else if (request.Method == "register") {
                return await UserRepository.RegisterAsync(context, request);
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

mkdir -p SayingHelloWebApi/Params

FILE=SayingHelloWebApi/Params/LoginParams.cs

cat > $FILE << EOF
using System.Text.Json.Serialization;

namespace SayingHelloWebApi.Params;

public class LoginParams
{
    [JsonPropertyName("password")]
    public string Password { get; set; }

    [JsonPropertyName("username")]
    public string Username { get; set; }
}
EOF

git add $FILE

FILE=SayingHelloWebApi/Params/NewGreetingParams.cs

cat > $FILE << EOF
using System.Text.Json.Serialization;

namespace SayingHelloWebApi.Params;

public class NewGreetingParams
{
    [JsonPropertyName("name")]
    public string Name { get; set; }
}
EOF

git add $FILE

FILE=SayingHelloWebApi/Params/RegisterParams.cs

cat > $FILE << EOF
using System.Text.Json.Serialization;

namespace SayingHelloWebApi.Params;

public class RegisterParams
{
    [JsonPropertyName("confirm")]
    public string Confirm { get; set; }

    [JsonPropertyName("email")]
    public string Email { get; set; }

    [JsonPropertyName("password")]
    public string Password { get; set; }

    [JsonPropertyName("username")]
    public string Username { get; set; }
}
EOF

git add $FILE
git commit --message="Added params."

FILE=SayingHelloWebApi/Properties/launchSettings.json

SERVER=$(jq '.profiles.http.applicationUrl' $FILE)

FILE=SayingHelloWebApi/Program.cs

cat > $FILE << EOF
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using SayingHelloWebApi.Data;
using SayingHelloWebApi.Entities;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection") ??
    throw new InvalidOperationException("Connection string 'DefaultConnection' not found.");

builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseNpgsql(connectionString));

builder.Services.AddIdentity<User, Role>()
                .AddEntityFrameworkStores<ApplicationDbContext>()
                .AddDefaultTokenProviders();

builder.Services.AddControllers();
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var ClientUrl = Environment.GetEnvironmentVariable("CLIENT_URL") ?? $SERVER;

var MyAllowSpecificOrigins = "_myAllowSpecificOrigins";

builder.Services.AddCors(options =>
{
    options.AddPolicy(MyAllowSpecificOrigins,
        policy =>
        {
            policy.WithOrigins(ClientUrl)
                .AllowAnyHeader()
                .AllowAnyMethod();
        });
});

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

using (var scope = app.Services.CreateScope())
{
    var services = scope.ServiceProvider;

    var context = services.GetRequiredService<ApplicationDbContext>();
    // Note: if you're having trouble with EF, database schema, etc.,
    // uncomment the line below to re-create the database upon each run.
    //context.Database.EnsureDeleted();
    context.Database.EnsureCreated();
    DBInitializer.Initialize(context);
}


app.UseHttpsRedirection();

app.UseAuthorization();

app.MapControllers();

app.UseCors(MyAllowSpecificOrigins);

app.Run();

public partial class Program {}
EOF

git add $FILE
git commit --message "Updated Program class."

mkdir -p SayingHelloWebApi/Repositories

FILE=SayingHelloWebApi/Repositories/GreetingRepository.cs

cat > $FILE << EOF
using Microsoft.EntityFrameworkCore;
using SayingHelloLibrary.Domain;
using SayingHelloLibrary.JsonRpc;
using SayingHelloWebApi.Data;
using SayingHelloWebApi.Entities;
using SayingHelloWebApi.Params;
using SayingHelloWebApi.Results;
using System.Text.Json;

namespace SayingHelloWebApi.Repositories;

public static class GreetingRepository
{
    public static async Task<JsonRpcResponse> GetAllGreetingsAsync(ApplicationDbContext context, JsonRpcRequest request)
    {
        var greetings = await context.Greetings.ToListAsync();

        return new JsonRpcResponse
        {
            Id = request.Id,
            JsonRpc = request.JsonRpc,
            Result = new GetAllGreetingsResult
            {
                Greetings = greetings
            },
        };
    }

    public static async Task<JsonRpcResponse> NewGreetingAsync(ApplicationDbContext context, JsonRpcRequest request)
    {
        var newGreetingParams = JsonSerializer.Deserialize<NewGreetingParams>(request.Params.GetRawText());
        var name = newGreetingParams.Name.Trim();

        var greeting = await context.Greetings.Where(greeting => greeting.Name == name).FirstOrDefaultAsync();
        if (greeting != null) {
            return new JsonRpcResponse
            {
                Id = request.Id,
                JsonRpc = request.JsonRpc,
                Result = new NewGreetingResult
                {
                    Message = greeting.Message
                },
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

        return new JsonRpcResponse
        {
            Id = request.Id,
            JsonRpc = request.JsonRpc,
            Result = new NewGreetingResult
            {
                Message = message
            },
        };
    }
}
EOF

git add $FILE

FILE=SayingHelloWebApi/Repositories/UserRepository.cs

cat > $FILE << EOF
using SayingHelloLibrary.JsonRpc;
using SayingHelloWebApi.Data;
using SayingHelloWebApi.Params;
using SayingHelloWebApi.Results;
using System.Text.Json;
using System.Text.RegularExpressions;

namespace SayingHelloWebApi.Repositories;

public static class UserRepository
{
    public static async Task<JsonRpcResponse> LoginAsync(ApplicationDbContext context, JsonRpcRequest request)
    {
        var loginParams = JsonSerializer.Deserialize<LoginParams>(request.Params.GetRawText());
        var password = loginParams.Password;
        var username = loginParams.Username.Trim();

        if (password.Length < 8) {
            return new JsonRpcResponse {
                Id = request.Id,
                JsonRpc = request.JsonRpc,
                Error = new JsonRpcError {
                    Code = 2,
                    Message = "Password must be at least 8 characters.",
                },
            };
        }

        if (username.Length < 1) {
            return new JsonRpcResponse {
                Id = request.Id,
                JsonRpc = request.JsonRpc,
                Error = new JsonRpcError {
                    Code = 3,
                    Message = "Username must be at least 1 character.",
                },
            };
        }

        return new JsonRpcResponse {
            Id = request.Id,
            JsonRpc = request.JsonRpc,
            Result = new LoginResult {},
        };
    }

    public static async Task<JsonRpcResponse> LogoutAsync(ApplicationDbContext context, JsonRpcRequest request)
    {
        return new JsonRpcResponse {
            Id = request.Id,
            JsonRpc = request.JsonRpc,
        };
    }

    public static async Task<JsonRpcResponse> RegisterAsync(ApplicationDbContext context, JsonRpcRequest request)
    {
        var registerParams = JsonSerializer.Deserialize<RegisterParams>(request.Params.GetRawText());
        var confirm = registerParams.Confirm;
        var email = registerParams.Email.Trim();
        var password = registerParams.Password;
        var username = registerParams.Username.Trim();

        if (confirm != password) {
            return new JsonRpcResponse {
                Id = request.Id,
                JsonRpc = request.JsonRpc,
                Error = new JsonRpcError {
                    Code = 1,
                    Message = "Passwords do not match.",
                },
            };
        }

        if (password.Length < 8) {
            return new JsonRpcResponse {
                Id = request.Id,
                JsonRpc = request.JsonRpc,
                Error = new JsonRpcError {
                    Code = 2,
                    Message = "Password must be at least 8 characters.",
                },
            };
        }

        if (username.Length < 1) {
            return new JsonRpcResponse {
                Id = request.Id,
                JsonRpc = request.JsonRpc,
                Error = new JsonRpcError {
                    Code = 3,
                    Message = "Username must be at least 1 character.",
                },
            };
        }

        if (email.Length < 1) {
            return new JsonRpcResponse {
                Id = request.Id,
                JsonRpc = request.JsonRpc,
                Error = new JsonRpcError {
                    Code = 4,
                    Message = "Email must be at least 1 character.",
                },
            };
        }

        if (!Regex.Match(email, "^.*@.*[.].*$").Success) {
            return new JsonRpcResponse {
                Id = request.Id,
                JsonRpc = request.JsonRpc,
                Error = new JsonRpcError {
                    Code = 5,
                    Message = "Email must have an amperat and a period.",
                },
            };
        }

        return new JsonRpcResponse {
            Id = request.Id,
            JsonRpc = request.JsonRpc,
        };
    }
}
EOF

git add $FILE
git commit --message="Added repository files."

mkdir -p SayingHelloWebApi/Results

FILE=SayingHelloWebApi/Results/GetAllGreetingsResult.cs

cat > $FILE << EOF
using SayingHelloWebApi.Entities;
using System.Text.Json.Serialization;

namespace SayingHelloWebApi.Results;

public class GetAllGreetingsResult
{
    [JsonPropertyName("greetings")]
    public List<Greeting> Greetings { get; set; }
}
EOF

git add $FILE

FILE=SayingHelloWebApi/Results/LoginResult.cs

cat > $FILE << EOF
namespace SayingHelloWebApi.Results;

public class LoginResult
{
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

git add $FILE

npx prettier --write .
git commit --message "Added saying hello form."
git push --force

cd ..

CLIENT="http://localhost:3000"

# type - add run scripts
./intrepion-apps/new/common/type/full_stack/typescript-react-typescript-csharp-dotnet-webapi/add_run_scripts.sh $CLIENT $KEBOB $PROJECT $SERVER

popd

echo "Completed $SCRIPT"
