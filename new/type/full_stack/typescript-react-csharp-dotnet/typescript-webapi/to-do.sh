#!/usr/bin/env bash

SCRIPT=$0

echo " - Running $SCRIPT"

pushd .

cd ..
pwd

CLIENT="http://localhost:3000"
CLIENT_FRAMEWORK=typescript-react
CLIENT_TEMPLATE=typescript
KEBOB=to-do
PASCAL=ToDo
SERVER_FRAMEWORK=csharp-dotnet
SERVER_TEMPLATE=webapi

CLIENT_REPOSITORY=intrepion-$KEBOB-json-rpc-client-web-$CLIENT_FRAMEWORK-$CLIENT_TEMPLATE
FRAMEWORK=$SERVER_FRAMEWORK
PROJECT=${PASCAL}WebApi
SERVER_REPOSITORY=intrepion-$KEBOB-json-rpc-server-$SERVER_FRAMEWORK-$SERVER_TEMPLATE
TEMPLATE=$SERVER_TEMPLATE

REPOSITORY=$SERVER_REPOSITORY

# framework - the works
./intrepion-apps/new/common/type/full_stack/$FRAMEWORK/$TEMPLATE/the_works.sh $CLIENT $FRAMEWORK $KEBOB $PASCAL $PROJECT $REPOSITORY $TEMPLATE

# project - add to do
cd $REPOSITORY
pwd

mkdir -p ToDoTests/Domain

FILE=ToDoTests/Domain/ToDoItemTest.cs

cat > $FILE << EOF
using ToDoLibrary.Domain;

namespace ToDoTests.Domain;

public class ToDoItemTest
{
    [Theory]
    [InlineData("", "make a to do list")]
    [InlineData("do the dishes", "do the dishes")]
    [InlineData("take out the trash", "take out the trash")]
    public void TestToDoItem_CreateToDoItem_HappyPath(string actualText, string expectedText)
    {
        // Arrange
        var expected = new ToDoItem {
            Complete = false,
            Text = expectedText,
            Visible = true,
        };

        // Act
        var actual = ToDoItem.CreateToDoItem(actualText);

        // Assert
        Assert.Equal(expected.Complete, actual.Complete);
        Assert.Equal(expected.Text, actual.Text);
        Assert.Equal(expected.Visible, actual.Visible);
    }

    [Theory]
    [InlineData("   do the dishes", "do the dishes")]
    [InlineData("take out the trash   ", "take out the trash")]
    public void TestToDoItem_CreateToDoItem_TrimsText(string actualText, string expectedText)
    {
        // Arrange
        var expected = new ToDoItem {
            Complete = false,
            Visible = true,
            Text = expectedText,
        };

        // Act
        var actual = ToDoItem.CreateToDoItem(actualText);

        // Assert
        Assert.Equal(expected.Complete, actual.Complete);
        Assert.Equal(expected.Text, actual.Text);
        Assert.Equal(expected.Visible, actual.Visible);
    }

    [Fact]
    public void TestToDoItem_MakeComplete() {
        // Arrange
        var expected = new ToDoItem {
            Complete = true,
            Visible = true,
            Text = "do the dishes",
        };

        // Act
        var actual = ToDoItem.CreateToDoItem("do the dishes");
        actual.MakeComplete();

        // Assert
        Assert.Equal(expected.Complete, actual.Complete);
        Assert.Equal(expected.Text, actual.Text);
        Assert.Equal(expected.Visible, actual.Visible);
    }

    [Fact]
    public void TestToDoItem_MakeHidden() {
        // Arrange
        var expected = new ToDoItem {
            Complete = false,
            Visible = false,
            Text = "do the dishes",
        };

        // Act
        var actual = ToDoItem.CreateToDoItem("do the dishes");
        actual.MakeHidden();

        // Assert
        Assert.Equal(expected.Complete, actual.Complete);
        Assert.Equal(expected.Text, actual.Text);
        Assert.Equal(expected.Visible, actual.Visible);
    }

    [Fact]
    public void TestToDoItem_Complete_ThenMakeIncomplete() {
        // Arrange
        var expected = new ToDoItem {
            Complete = false,
            Visible = true,
            Text = "do the dishes",
        };

        // Act
        var actual = ToDoItem.CreateToDoItem("do the dishes");
        actual.MakeComplete();
        actual.MakeIncomplete();

        // Assert
        Assert.Equal(expected.Complete, actual.Complete);
        Assert.Equal(expected.Text, actual.Text);
        Assert.Equal(expected.Visible, actual.Visible);
    }

    [Fact]
    public void TestToDoItem_MakeHidden_ThenMakeVisible() {
        // Arrange
        var expected = new ToDoItem {
            Complete = false,
            Visible = true,
            Text = "do the dishes",
        };

        // Act
        var actual = ToDoItem.CreateToDoItem("do the dishes");
        actual.MakeHidden();
        actual.MakeVisible();

        // Assert
        Assert.Equal(expected.Complete, actual.Complete);
        Assert.Equal(expected.Text, actual.Text);
        Assert.Equal(expected.Visible, actual.Visible);
    }
}
EOF

git add $FILE
git commit --message="Added to do tests."

mkdir -p ToDoLibrary/Domain

FILE=ToDoLibrary/Domain/ToDoItem.cs

cat > $FILE << EOF
using System.Text.Json.Serialization;

namespace ToDoLibrary.Domain;

public class ToDoItem
{
    [JsonPropertyName("complete")]
    public bool Complete { get; set; }

    [JsonPropertyName("text")]
    public string Text { get; set; }

    [JsonPropertyName("visible")]
    public bool Visible { get; set; }

    public static ToDoItem CreateToDoItem(string text) {
        text = text.Trim();

        if (string.IsNullOrEmpty(text)) {
            text = "make a to do list";
        }

        return new ToDoItem() {
            Complete = false,
            Text = text,
            Visible = true,
        };
    }

    public void MakeComplete() {
        Complete = true;
    }

    public void MakeHidden() {
        Visible = false;
    }

    public void MakeIncomplete() {
        Complete = false;
    }

    public void MakeVisible() {
        Visible = true;
    }    
}
EOF

git add $FILE
git commit --message="Added to do code."

FILE=ToDoWebApi/appsettings.Development.json

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

FILE=ToDoWebApi/appsettings.json

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

FILE=ToDoWebApi/Controllers/ToDoController.cs

cat > $FILE << EOF
using Microsoft.AspNetCore.Mvc;
using ToDoLibrary.JsonRpc;
using ToDoWebApi.JsonRpc;

namespace ToDoWebApi.Controllers;

[ApiController]
[Route("/")]
public class ToDoController : ControllerBase
{
    private readonly IJsonRpcService _jsonRpcService;
    private readonly ILogger<ToDoController> _logger;

    public ToDoController(
        IJsonRpcService jsonRpcService,
        ILogger<ToDoController> logger
        )
    {
        _jsonRpcService = jsonRpcService;
        _logger = logger;
    }

    [HttpPost(Name = "PostToDo")]
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
git commit --message="Added to do controller."

mkdir -p ToDoWebApi/Data

FILE=ToDoWebApi/Data/ApplicationDbContext.cs

cat > $FILE << EOF
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using ToDoWebApi.Entities;

namespace ToDoWebApi.Data;

public class ApplicationDbContext : IdentityDbContext<ApplicationUser, ApplicationRole, Guid>
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : base(options)
    {
        Database.EnsureCreated();
        DbInitializer.Initialize(this);
    }

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);
    }

    public DbSet<ToDoItemEntity> ToDoItems { get; set; }
}
EOF

git add $FILE

FILE=ToDoWebApi/Data/DbInitializer.cs

cat > $FILE << EOF
namespace ToDoWebApi.Data;

public static class DbInitializer
{
    public static void Initialize(ApplicationDbContext context)
    {
    }
}
EOF

git add $FILE
git commit --message="Added data files."

mkdir -p ToDoWebApi/Entities

FILE=ToDoWebApi/Entities/ApplicationRole.cs

cat > $FILE << EOF
using Microsoft.AspNetCore.Identity;

namespace ToDoWebApi.Entities;

public class ApplicationRole : IdentityRole<Guid>
{
}
EOF

git add $FILE

FILE=ToDoWebApi/Entities/ApplicationUser.cs

cat > $FILE << EOF
using Microsoft.AspNetCore.Identity;

namespace ToDoWebApi.Entities;

public class ApplicationUser : IdentityUser<Guid>
{
}
EOF

git add $FILE

FILE=ToDoWebApi/Entities/ToDoItemEntity.cs

cat > $FILE << EOF
using System.Text.Json.Serialization;
using ToDoLibrary.Domain;

namespace ToDoWebApi.Entities;

public class ToDoItemEntity : ToDoItem
{
    [JsonPropertyName("id")]
    public Guid Id { get; set; }

    [JsonPropertyName("guid")]
    public Guid Guid { get; set; }
}
EOF

git add $FILE
git commit --message="Added entities."

mkdir -p ToDoWebApi/JsonRpc

FILE=ToDoWebApi/JsonRpc/FunctionCall.cs

cat > $FILE << EOF
namespace ToDoWebApi.JsonRpc;

public class FunctionCall
{
    public List<Parameter> Parameters { get; set; }
}
EOF

git add $FILE

FILE=ToDoWebApi/JsonRpc/FunctionCalls.cs

cat > $FILE << EOF
namespace ToDoWebApi.JsonRpc;

public static class FunctionCalls
{
    public static Dictionary<string, FunctionCall> Dictionary = new Dictionary<string, FunctionCall>
    {
        {
            "get_all_to_do_items", new FunctionCall
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
            "new_to_do_item", new FunctionCall
            {
                Parameters = new List<Parameter>
                {
                    new Parameter { Name = "complete", Kind = "bool" },
                    new Parameter { Name = "name", Kind = "string" },
                    new Parameter { Name = "visible", Kind = "bool" },
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

FILE=ToDoWebApi/JsonRpc/IJsonRpcService.cs

cat > $FILE << EOF
using ToDoLibrary.JsonRpc;

namespace ToDoWebApi.JsonRpc
{
    public interface IJsonRpcService : IDisposable
    {
        Task<JsonRpcResponse> ProcessRequest(string json, Dictionary<string, FunctionCall> functionCalls);
    }
}
EOF

git add $FILE

FILE=ToDoWebApi/JsonRpc/JsonRpcService.cs

cat > $FILE << EOF
using Microsoft.AspNetCore.Identity;
using ToDoLibrary.JsonRpc;
using ToDoWebApi.Data;
using ToDoWebApi.Entities;
using ToDoWebApi.Repositories;
using System.Text.Json;

namespace ToDoWebApi.JsonRpc;

public class JsonRpcService : IJsonRpcService, IDisposable
{
    private readonly IConfiguration _configuration;
    private readonly ApplicationDbContext _context;
    private readonly IToDoItemRepository _toDoItemRepository;
    private readonly SignInManager<ApplicationUser> _signInManager;
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly IUserRepository _userRepository;

    public JsonRpcService(
        IConfiguration configuration,
        ApplicationDbContext context,
        IToDoItemRepository toDoItemRepository,
        SignInManager<ApplicationUser> signInManager,
        UserManager<ApplicationUser> userManager,
        IUserRepository userRepository
        )
    {
        _context = context;
        _configuration = configuration;
        _toDoItemRepository = toDoItemRepository;
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

            if (request.Method == "get_all_to_do_items") {
                return await _toDoItemRepository.GetAllToDoItemsAsync(request);
            } else if (request.Method == "login") {
                return await _userRepository.LoginAsync(request);
            } else if (request.Method == "logout") {
                return await _userRepository.LogoutAsync(request);
            } else if (request.Method == "new_to_do_item") {
                return await _toDoItemRepository.NewToDoItemAsync(request);
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

FILE=ToDoWebApi/JsonRpc/Parameter.cs

cat > $FILE << EOF
namespace ToDoWebApi.JsonRpc;

public class Parameter
{
    public string Kind { get; set; }
    public string Name { get; set; }
    public object Value { get; set; }
}
EOF

git add $FILE
git commit --message="Added project json rpc files."

mkdir -p ToDoWebApi/Params

FILE=ToDoWebApi/Params/LoginParams.cs

cat > $FILE << EOF
using System.Text.Json.Serialization;

namespace ToDoWebApi.Params;

public class LoginParams
{
    [JsonPropertyName("password")]
    public string Password { get; set; }

    [JsonPropertyName("username")]
    public string UserName { get; set; }
}
EOF

git add $FILE

FILE=ToDoWebApi/Params/NewToDoItemParams.cs

cat > $FILE << EOF
using System.Text.Json.Serialization;

namespace ToDoWebApi.Params;

public class NewToDoItemParams
{
    [JsonPropertyName("text")]
    public string Text { get; set; }
}
EOF

git add $FILE

FILE=ToDoWebApi/Params/RegisterParams.cs

cat > $FILE << EOF
using System.Text.Json.Serialization;

namespace ToDoWebApi.Params;

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

FILE=ToDoWebApi/Properties/launchSettings.json

SERVER=$(jq '.profiles.http.applicationUrl' $FILE)

FILE=ToDoWebApi/Program.cs

cat > $FILE << EOF
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using ToDoWebApi.Data;
using ToDoWebApi.Entities;
using ToDoWebApi.JsonRpc;
using ToDoWebApi.Repositories;
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
builder.Services.AddScoped<IToDoItemRepository, ToDoItemRepository>();
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
    DbInitializer.Initialize(context);
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

mkdir -p ToDoWebApi/Repositories

FILE=ToDoWebApi/Repositories/ToDoItemRepository.cs

cat > $FILE << EOF
using Microsoft.EntityFrameworkCore;
using ToDoLibrary.Domain;
using ToDoLibrary.JsonRpc;
using ToDoWebApi.Data;
using ToDoWebApi.Entities;
using ToDoWebApi.Params;
using ToDoWebApi.Results;
using System.Text.Json;

namespace ToDoWebApi.Repositories;

public class ToDoItemRepository : IToDoItemRepository, IDisposable
{
    private readonly ApplicationDbContext _context;

    public ToDoItemRepository(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<JsonRpcResponse> GetAllToDoItemsAsync(JsonRpcRequest request)
    {
        var toDoItems = await _context.ToDoItems.ToListAsync();

        return new JsonRpcResponse
        {
            Id = request.Id,
            JsonRpc = request.JsonRpc,
            Result = new GetAllToDoItemsResult
            {
                ToDoItems = toDoItems.Select(toDoItem => new GetAllToDoItemsResultToDoItem
                {
                    Complete = toDoItem.Complete,
                    Guid = toDoItem.Guid,
                    Text = toDoItem.Text,
                    Visible = toDoItem.Visible,
                }).ToList()
            },
        };
    }

    public async Task<JsonRpcResponse> NewToDoItemAsync(JsonRpcRequest request)
    {
        var newToDoItemParams = JsonSerializer.Deserialize<NewToDoItemParams>(request.Params.GetRawText());
        var text = newToDoItemParams.Text.Trim();

        var toDoItem = await _context.ToDoItems.Where(toDoItem => toDoItem.Text == text).FirstOrDefaultAsync();
        if (toDoItem != null) {
            return new JsonRpcResponse
            {
                Id = request.Id,
                JsonRpc = request.JsonRpc,
                Result = new NewToDoItemResult
                {
                    Text = toDoItem.Text
                },
            };
        }

        var message = ToDoItem.CreateToDoItem(text);

        toDoItem = new ToDoItemEntity
        {
            Text = text,
        };

        await _context.AddAsync(toDoItem);
        _context.SaveChanges();

        return new JsonRpcResponse
        {
            Id = request.Id,
            JsonRpc = request.JsonRpc,
            Result = new NewToDoItemResult
            {
                Text = text
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

FILE=ToDoWebApi/Repositories/IToDoItemRepository.cs

cat > $FILE << EOF
using ToDoLibrary.JsonRpc;

namespace ToDoWebApi.Repositories
{
    public interface IToDoItemRepository : IDisposable
    {
        Task<JsonRpcResponse> GetAllToDoItemsAsync(JsonRpcRequest request);
        Task<JsonRpcResponse> NewToDoItemAsync(JsonRpcRequest request);
    }
}
EOF

git add $FILE

FILE=ToDoWebApi/Repositories/IUserRepository.cs

cat > $FILE << EOF
using ToDoLibrary.JsonRpc;

namespace ToDoWebApi.Repositories
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

FILE=ToDoWebApi/Repositories/UserRepository.cs

cat > $FILE << EOF
using Microsoft.AspNetCore.Identity;
using Microsoft.IdentityModel.Tokens;
using ToDoLibrary.JsonRpc;
using ToDoWebApi.Data;
using ToDoWebApi.Entities;
using ToDoWebApi.Params;
using ToDoWebApi.Results;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using System.Text.Json;

namespace ToDoWebApi.Repositories;

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

mkdir -p ToDoWebApi/Results

FILE=ToDoWebApi/Results/GetAllToDoItemsResult.cs

cat > $FILE << EOF
using System.Text.Json.Serialization;

namespace ToDoWebApi.Results;

public class GetAllToDoItemsResult
{
    [JsonPropertyName("to_do_items")]
    public List<GetAllToDoItemsResultToDoItem> ToDoItems { get; set; }
}
EOF

git add $FILE

FILE=ToDoWebApi/Results/GetAllToDoItemsResultToDoItem.cs

cat > $FILE << EOF
using System.Text.Json.Serialization;

namespace ToDoWebApi.Results;

public class GetAllToDoItemsResultToDoItem
{
    [JsonPropertyName("complete")]
    public bool Complete { get; set; }

    [JsonPropertyName("guid")]
    public Guid Guid { get; set; }

    [JsonPropertyName("Text")]
    public string Text { get; set; }

    [JsonPropertyName("visible")]
    public bool Visible { get; set; }
}
EOF

git add $FILE

FILE=ToDoWebApi/Results/LoginResult.cs

cat > $FILE << EOF
namespace ToDoWebApi.Results;

public class LoginResult
{
    public object Token { get; set; }
}
EOF

git add $FILE

FILE=ToDoWebApi/Results/NewToDoItemResult.cs

cat > $FILE << EOF
using System.Text.Json.Serialization;

namespace ToDoWebApi.Results;

public class NewToDoItemResult
{
    [JsonPropertyName("text")]
    public string Text { get; set; }
}
EOF

git add $FILE
git commit --message="Added result files."

git push --force

FILE=ToDoWebApi/Properties/launchSettings.json

SERVER=$(jq '.profiles.http.applicationUrl' $FILE)

cd ..

FRAMEWORK=$CLIENT_FRAMEWORK
REPOSITORY=$CLIENT_REPOSITORY
TEMPLATE=$CLIENT_TEMPLATE

# framework - the works
./intrepion-apps/new/common/type/full_stack/$FRAMEWORK/$TEMPLATE/the_works.sh $FRAMEWORK $REPOSITORY $SERVER $TEMPLATE

# project - add to do
cd $REPOSITORY
pwd

FILE=src/components/Home.tsx

cat > $FILE << EOF
import React from "react";
import ToDoItemForm from "./ToDoItemForm";

const Home = () => {
  return (
    <>
      <h1>Home</h1>
      <ToDoItemForm />
    </>
  );
};

export default Home;
EOF

git add $FILE

FILE=src/components/ToDoItemForm.tsx

cat > $FILE << EOF
import React, { useEffect, useState } from "react";
import ToDoItem from "./ToDoItem";
import { v4 } from "uuid";
import { ToDoItemType } from "../types/ToDoItemType";

const SERVER_URL = process.env.REACT_APP_SERVER_URL ?? "http://localhost:3000";

const ToDoItemForm: React.FC = () => {
  const [toDoItems, setToDoItems] = useState<ToDoItemType[]>([]);
  const [text, setText] = useState("");
  const [message, setMessage] = useState("Hello, world!");

  useEffect(() => {
    fetch(SERVER_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        id: v4(),
        jsonrpc: "2.0",
        method: "get_all_to_do_items",
      }),
    })
      .then((response) => response.json())
      .then((responseJson) => {
        if (responseJson.result) {
          const result = responseJson.result;
          setToDoItems(result.to_do_items);
        } else if (responseJson.error) {
          console.error(responseJson.error);
        }
      })
      .catch((error) => {
        console.error(error);
      });
  }, [message]);

  const handleChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    setText(event.target.value);
  };

  const callToDo = (event: React.MouseEvent<HTMLElement>) => {
    event.preventDefault();
    fetch(SERVER_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        id: v4(),
        jsonrpc: "2.0",
        method: "new_to_do_item",
        params: { text },
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
      <h2>To Do</h2>
      <input type="text" value={text} onChange={handleChange} />
      <button onClick={callToDo}>New To Do</button>
      <div>{message}</div>
      <p>Previous ToDoItems</p>
      <ul>
        {toDoItems.map((toDoItem) => (
          <li key={toDoItem.guid}>
            <ToDoItem
              complete={toDoItem.complete}
              guid={toDoItem.guid}
              text={toDoItem.text}
              visible={toDoItem.visible}
            />
          </li>
        ))}
      </ul>
    </div>
  );
};

export default ToDoItemForm;
EOF

git add $FILE

FILE=src/components/ToDoItem.tsx

cat > $FILE << EOF
import React from "react";

export interface ToDoItemInterface {
  complete: boolean;
  guid: string;
  text: string;
  visible: boolean;
}

const ToDoItem = (props: ToDoItemInterface) => {
  const { complete, guid, text, visible } = props;

  return (
    <>
      {guid}: {complete}, {text}, {visible}
    </>
  );
};

export default ToDoItem;
EOF

git add $FILE

mkdir -p src/types

FILE=src/types/ToDoItemType.ts

cat > $FILE << EOF
export type ToDoItemType = {
  complete: boolean;
  guid: string;
  text: string;
  visible: boolean;
};
EOF

git add $FILE
git commit --message "Added to do form."

npx prettier --write .
git add --all
git commit --message "npx prettier --write ."

git push --force

cd ..

CLIENT="http://localhost:3000"

# type - add run scripts
./intrepion-apps/new/common/type/full_stack/typescript-react-typescript-csharp-dotnet-webapi/add_run_scripts.sh $CLIENT $KEBOB $PROJECT $SERVER

popd

echo "Complete $SCRIPT"
