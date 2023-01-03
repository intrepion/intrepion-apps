#!/usr/bin/env bash

SCRIPT=$0

echo "Running $SCRIPT"

pushd .

cd ..

CLIENT="http://localhost:3000"
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
  "JwtKey": "SOME_RANDOM_KEY_DO_NOT_SHARE",
  "JwtIssuer": "http://yourdomain.com",
  "JwtExpireDays": 30,
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  }
}
EOF

git add $FILE

FILE=SayingHelloWebApi/appsettings.json

cat > $FILE << EOF
{
  "AllowedHosts": "*",
  "JwtExpireDays": 30,
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
using SayingHelloWebApi.JsonRpc;

namespace SayingHelloWebApi.Controllers;

[ApiController]
[Route("/")]
public class SayingHelloController : ControllerBase
{
    private readonly IJsonRpcService _jsonRpcService;
    private readonly ILogger<SayingHelloController> _logger;

    public SayingHelloController(
        IJsonRpcService jsonRpcService,
        ILogger<SayingHelloController> logger
        )
    {
        _jsonRpcService = jsonRpcService;
        _logger = logger;
    }

    [HttpPost(Name = "PostSayingHello")]
    public async Task<JsonRpcResponse> Post()
    {
        Request.EnableBuffering();

        Request.Body.Position = 0;

        var json = await new StreamReader(Request.Body).ReadToEndAsync();

        return await _jsonRpcService.ProcessRequest(json, FunctionCalls.Dictionary);
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

public class ApplicationDbContext : IdentityDbContext<ApplicationUser, ApplicationRole, Guid>
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

FILE=SayingHelloWebApi/Entities/ApplicationRole.cs

cat > $FILE << EOF
using Microsoft.AspNetCore.Identity;

namespace SayingHelloWebApi.Entities;

public class ApplicationRole : IdentityRole<Guid>
{
}
EOF

git add $FILE

FILE=SayingHelloWebApi/Entities/ApplicationUser.cs

cat > $FILE << EOF
using Microsoft.AspNetCore.Identity;

namespace SayingHelloWebApi.Entities;

public class ApplicationUser : IdentityUser<Guid>
{
}
EOF

git add $FILE

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
                    new Parameter { Name = "username", Kind = "string" },
                    new Parameter { Name = "password", Kind = "string" },
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

FILE=SayingHelloWebApi/JsonRpc/IJsonRpcService.cs

cat > $FILE << EOF
using SayingHelloLibrary.JsonRpc;

namespace SayingHelloWebApi.JsonRpc
{
    public interface IJsonRpcService : IDisposable
    {
        Task<JsonRpcResponse> ProcessRequest(string json, Dictionary<string, FunctionCall> functionCalls);
    }
}
EOF

git add $FILE

FILE=SayingHelloWebApi/JsonRpc/JsonRpcService.cs

cat > $FILE << EOF
using Microsoft.AspNetCore.Identity;
using SayingHelloLibrary.JsonRpc;
using SayingHelloWebApi.Data;
using SayingHelloWebApi.Entities;
using SayingHelloWebApi.Repositories;
using System.Text.Json;

namespace SayingHelloWebApi.JsonRpc;

public class JsonRpcService : IJsonRpcService, IDisposable
{
    private readonly IConfiguration _configuration;
    private readonly ApplicationDbContext _context;
    private readonly IGreetingRepository _greetingRepository;
    private readonly SignInManager<ApplicationUser> _signInManager;
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly IUserRepository _userRepository;

    public JsonRpcService(
        IConfiguration configuration,
        ApplicationDbContext context,
        IGreetingRepository greetingRepository,
        SignInManager<ApplicationUser> signInManager,
        UserManager<ApplicationUser> userManager,
        IUserRepository userRepository
        )
    {
        _context = context;
        _configuration = configuration;
        _greetingRepository = greetingRepository;
        _signInManager = signInManager;
        _userManager = userManager;
        _userRepository = userRepository;
    }

    public async Task<JsonRpcResponse> ProcessRequest(string json, Dictionary<string, FunctionCall> functionCalls)
    {
        if (string.IsNullOrEmpty(json) || double.TryParse(json, out _))
        {
            return new JsonRpcResponse
            {
                JsonRpc = "2.0",
                Error = new JsonRpcError
                {
                    Code = -32600,
                    Message = "Invalid Request - json is not found",
                },
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
                        Message = "Method not found",
                    },
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
                                    Message = "Invalid params - value is null",
                                },
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
                                    Message = "Invalid params - value is not of the correct type",
                                },
                            };
                        }
                    }
                }
            }

            if (request.Method == "get_all_greetings") {
                return await _greetingRepository.GetAllGreetingsAsync(request);
            } else if (request.Method == "login") {
                return await _userRepository.LoginAsync(request);
            } else if (request.Method == "logout") {
                return await _userRepository.LogoutAsync(request);
            } else if (request.Method == "new_greeting") {
                return await _greetingRepository.NewGreetingAsync(request);
            } else if (request.Method == "register") {
                return await _userRepository.RegisterAsync(request);
            }

        } catch (JsonException) {
            return new JsonRpcResponse
            {
                JsonRpc = "2.0",
                Error = new JsonRpcError
                {
                    Code = -32700,
                    Message = "Parse error",
                },
            };
        } catch (Exception exception) {
            return new JsonRpcResponse
            {
                JsonRpc = "2.0",
                Error = new JsonRpcError
                {
                    Code = -32602,
                    Message = "Invalid Request - internal error",
                    Data = exception,
                },
            };
        }

        return new JsonRpcResponse
        {
            JsonRpc = "2.0",
            Error = new JsonRpcError
            {
                Code = -32600,
                Message = "Invalid Request",
            }
        };
    }

    private bool disposed = false;

    protected virtual void Dispose(bool disposing)
    {
        if (!this.disposed)
        {
            if (disposing)
            {
                _context.Dispose();
            }
        }
        this.disposed = true;
    }

    public void Dispose()
    {
        Dispose(true);
        GC.SuppressFinalize(this);
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
    public string UserName { get; set; }
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
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using SayingHelloWebApi.Data;
using SayingHelloWebApi.Entities;
using SayingHelloWebApi.JsonRpc;
using SayingHelloWebApi.Repositories;
using System.IdentityModel.Tokens.Jwt;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

var connectionString = builder.Configuration.GetConnectionString("DefaultConnection") ??
    throw new InvalidOperationException("Connection string 'DefaultConnection' not found.");

builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseNpgsql(connectionString));

builder.Services.AddIdentity<ApplicationUser, ApplicationRole>()
    .AddEntityFrameworkStores<ApplicationDbContext>()
    .AddDefaultTokenProviders();

JwtSecurityTokenHandler.DefaultInboundClaimTypeMap.Clear();

builder.Services
    .AddAuthentication(options =>
    {
        options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
        options.DefaultScheme = JwtBearerDefaults.AuthenticationScheme;
        options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
        
    })
    .AddJwtBearer(cfg =>
    {
        var jwtIssuer = builder.Configuration["JwtIssuer"] ?? Environment.GetEnvironmentVariable("JWT_ISSUER");
        var jwtKey = builder.Configuration["JwtKey"] ?? Environment.GetEnvironmentVariable("JWT_KEY");
        cfg.RequireHttpsMetadata = false;
        cfg.SaveToken = true;
        cfg.TokenValidationParameters = new TokenValidationParameters
        {
            ValidIssuer = jwtIssuer,
            ValidAudience = jwtIssuer,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey)),
            ClockSkew = TimeSpan.Zero
        };
    });

builder.Services.AddControllers();

builder.Services.AddScoped<IJsonRpcService, JsonRpcService>();
builder.Services.AddScoped<IGreetingRepository, GreetingRepository>();
builder.Services.AddScoped<IUserRepository, UserRepository>();

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

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

using (var scope = app.Services.CreateScope())
{
    var services = scope.ServiceProvider;

    var context = services.GetRequiredService<ApplicationDbContext>();
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

public class GreetingRepository : IGreetingRepository, IDisposable
{
    private readonly ApplicationDbContext _context;

    public GreetingRepository(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<JsonRpcResponse> GetAllGreetingsAsync(JsonRpcRequest request)
    {
        var greetings = await _context.Greetings.ToListAsync();

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

    public async Task<JsonRpcResponse> NewGreetingAsync(JsonRpcRequest request)
    {
        var newGreetingParams = JsonSerializer.Deserialize<NewGreetingParams>(request.Params.GetRawText());
        var name = newGreetingParams.Name.Trim();

        var greeting = await _context.Greetings.Where(greeting => greeting.Name == name).FirstOrDefaultAsync();
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

        await _context.AddAsync(greeting);
        _context.SaveChanges();

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

    private bool disposed = false;

    protected virtual void Dispose(bool disposing)
    {
        if (!this.disposed)
        {
            if (disposing)
            {
                _context.Dispose();
            }
        }
        this.disposed = true;
    }

    public void Dispose()
    {
        Dispose(true);
        GC.SuppressFinalize(this);
    }
}
EOF

git add $FILE

FILE=SayingHelloWebApi/Repositories/IGreetingRepository.cs

cat > $FILE << EOF
using SayingHelloLibrary.JsonRpc;

namespace SayingHelloWebApi.Repositories
{
    public interface IGreetingRepository : IDisposable
    {
        Task<JsonRpcResponse> GetAllGreetingsAsync(JsonRpcRequest request);
        Task<JsonRpcResponse> NewGreetingAsync(JsonRpcRequest request);
    }
}
EOF

git add $FILE

FILE=SayingHelloWebApi/Repositories/IUserRepository.cs

cat > $FILE << EOF
using SayingHelloLibrary.JsonRpc;

namespace SayingHelloWebApi.Repositories
{
    public interface IUserRepository : IDisposable
    {
        Task<JsonRpcResponse> LoginAsync(JsonRpcRequest request);
        Task<JsonRpcResponse> LogoutAsync(JsonRpcRequest request);
        Task<JsonRpcResponse> RegisterAsync(JsonRpcRequest request);
    }
}
EOF

git add $FILE

FILE=SayingHelloWebApi/Repositories/UserRepository.cs

cat > $FILE << EOF
using Microsoft.AspNetCore.Identity;
using Microsoft.IdentityModel.Tokens;
using SayingHelloLibrary.JsonRpc;
using SayingHelloWebApi.Data;
using SayingHelloWebApi.Entities;
using SayingHelloWebApi.Params;
using SayingHelloWebApi.Results;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using System.Text.Json;

namespace SayingHelloWebApi.Repositories;

public class UserRepository : IUserRepository, IDisposable
{
    private readonly IConfiguration _configuration;
    private readonly ApplicationDbContext _context;
    private readonly SignInManager<ApplicationUser> _signInManager;
    private readonly UserManager<ApplicationUser> _userManager;

    public UserRepository(
        IConfiguration configuration,
        ApplicationDbContext context,
        SignInManager<ApplicationUser> signInManager,
        UserManager<ApplicationUser> userManager
        )
    {
        _context = context;
        _configuration = configuration;
        _signInManager = signInManager;
        _userManager = userManager;
    }

    private async Task<object> GenerateJwtToken(string userName, ApplicationUser user)
    {
        var claims = new List<Claim>
        {
            new Claim(JwtRegisteredClaimNames.Sub, userName),
            new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
            new Claim(ClaimTypes.NameIdentifier, user.Id.ToString())
        };

        var jwtIssuer = _configuration["JwtIssuer"] ?? Environment.GetEnvironmentVariable("JWT_ISSUER");
        var jwtKey = _configuration["JwtKey"] ?? Environment.GetEnvironmentVariable("JWT_KEY");

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
        var expires = DateTime.Now.AddDays(Convert.ToDouble(_configuration["JwtExpireDays"]));

        var token = new JwtSecurityToken(
            jwtIssuer,
            jwtIssuer,
            claims,
            expires: expires,
            signingCredentials: creds
        );

        return new JwtSecurityTokenHandler().WriteToken(token);
    }
    
    public async Task<JsonRpcResponse> LoginAsync(JsonRpcRequest request)
    {
        var loginParams = JsonSerializer.Deserialize<LoginParams>(request.Params.GetRawText());
        var userName = loginParams.UserName.Trim();
        var password = loginParams.Password;

        var result = await _signInManager.PasswordSignInAsync(userName, password, false, false);

        if (result.Succeeded)
        {
            var appUser = _userManager.Users.SingleOrDefault(r => r.UserName == userName);
            var jwtToken = await GenerateJwtToken(userName, appUser);

            return new JsonRpcResponse {
                Id = request.Id,
                JsonRpc = request.JsonRpc,
                Result = new LoginResult {
                    Token = jwtToken,
                },
            };
        }

        return new JsonRpcResponse {
            Id = request.Id,
            JsonRpc = request.JsonRpc,
            Error = new JsonRpcError {
                Code = 7,
                Message = "Invalid login attempt.",
                Data = result,
            },
        };
    }

    public async Task<JsonRpcResponse> LogoutAsync(JsonRpcRequest request)
    {
        return new JsonRpcResponse {
            Id = request.Id,
            JsonRpc = request.JsonRpc,
        };
    }

    public async Task<JsonRpcResponse> RegisterAsync(JsonRpcRequest request)
    {
        var registerParams = JsonSerializer.Deserialize<RegisterParams>(request.Params.GetRawText());
        var confirm = registerParams.Confirm;
        var email = registerParams.Email.Trim();
        var password = registerParams.Password;
        var userName = registerParams.Username.Trim();

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

        var user = new ApplicationUser {
            Email = email,
            UserName = userName,
        };

        var result = await _userManager.CreateAsync(user, password);

        if (result.Succeeded)
        {
            return new JsonRpcResponse {
                Id = request.Id,
                JsonRpc = request.JsonRpc,
            };
        }

        return new JsonRpcResponse {
            Id = request.Id,
            JsonRpc = request.JsonRpc,
            Error = new JsonRpcError {
                Code = 6,
                Message = "User could not be created.",
                Data = result,
            },
        };
    }

    private bool disposed = false;

    protected virtual void Dispose(bool disposing)
    {
        if (!this.disposed)
        {
            if (disposing)
            {
                _context.Dispose();
            }
        }
        this.disposed = true;
    }

    public void Dispose()
    {
        Dispose(true);
        GC.SuppressFinalize(this);
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
    public object Token { get; set; }
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
./intrepion-apps/new/common/type/full_stack/$FRAMEWORK/$TEMPLATE/the_works.sh $FRAMEWORK $REPOSITORY $SERVER $TEMPLATE

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
      <h1>Home</h1>
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
import { v4 } from "uuid";

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
        id: v4(),
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
        id: v4(),
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
      <h2>Saying Hello</h2>
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
