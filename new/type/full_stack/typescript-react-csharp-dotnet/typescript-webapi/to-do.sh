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

FILE=ToDoWebApi/Properties/launchSettings.json

SERVER=$(jq '.profiles.http.applicationUrl' $FILE)

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

FILE=ToDoTests/Domain/ToDoListTest.cs

cat > $FILE << EOF
using ToDoLibrary.Domain;

namespace ToDoTests.Domain;

public class ToDoListTest
{
    [Theory]
    [InlineData("", "make a to do list")]
    [InlineData("do the dishes", "do the dishes")]
    [InlineData("take out the trash", "take out the trash")]
    public void TestToDoList_CreateToDoList_HappyPath(string actualTitle, string expectedTitle)
    {
        // Arrange
        var expected = new ToDoList {
            Complete = false,
            Title = expectedTitle,
            Visible = true,
        };

        // Act
        var actual = ToDoList.CreateToDoList(actualTitle);

        // Assert
        Assert.Equal(expected.Complete, actual.Complete);
        Assert.Equal(expected.Title, actual.Title);
        Assert.Equal(expected.Visible, actual.Visible);
    }

    [Theory]
    [InlineData("   do the dishes", "do the dishes")]
    [InlineData("take out the trash   ", "take out the trash")]
    public void TestToDoList_CreateToDoList_TrimsTitle(string actualTitle, string expectedTitle)
    {
        // Arrange
        var expected = new ToDoList {
            Complete = false,
            Visible = true,
            Title = expectedTitle,
        };

        // Act
        var actual = ToDoList.CreateToDoList(actualTitle);

        // Assert
        Assert.Equal(expected.Complete, actual.Complete);
        Assert.Equal(expected.Title, actual.Title);
        Assert.Equal(expected.Visible, actual.Visible);
    }

    [Fact]
    public void TestToDoList_MakeComplete() {
        // Arrange
        var expected = new ToDoList {
            Complete = true,
            Visible = true,
            Title = "do the dishes",
        };

        // Act
        var actual = ToDoList.CreateToDoList("do the dishes");
        actual.MakeComplete();

        // Assert
        Assert.Equal(expected.Complete, actual.Complete);
        Assert.Equal(expected.Title, actual.Title);
        Assert.Equal(expected.Visible, actual.Visible);
    }

    [Fact]
    public void TestToDoList_MakeHidden() {
        // Arrange
        var expected = new ToDoList {
            Complete = false,
            Visible = false,
            Title = "do the dishes",
        };

        // Act
        var actual = ToDoList.CreateToDoList("do the dishes");
        actual.MakeHidden();

        // Assert
        Assert.Equal(expected.Complete, actual.Complete);
        Assert.Equal(expected.Title, actual.Title);
        Assert.Equal(expected.Visible, actual.Visible);
    }

    [Fact]
    public void TestToDoList_Complete_ThenMakeIncomplete() {
        // Arrange
        var expected = new ToDoList {
            Complete = false,
            Visible = true,
            Title = "do the dishes",
        };

        // Act
        var actual = ToDoList.CreateToDoList("do the dishes");
        actual.MakeComplete();
        actual.MakeIncomplete();

        // Assert
        Assert.Equal(expected.Complete, actual.Complete);
        Assert.Equal(expected.Title, actual.Title);
        Assert.Equal(expected.Visible, actual.Visible);
    }

    [Fact]
    public void TestToDoList_MakeHidden_ThenMakeVisible() {
        // Arrange
        var expected = new ToDoList {
            Complete = false,
            Visible = true,
            Title = "do the dishes",
        };

        // Act
        var actual = ToDoList.CreateToDoList("do the dishes");
        actual.MakeHidden();
        actual.MakeVisible();

        // Assert
        Assert.Equal(expected.Complete, actual.Complete);
        Assert.Equal(expected.Title, actual.Title);
        Assert.Equal(expected.Visible, actual.Visible);
    }
}
EOF

git add $FILE
git commit --message="Added domain tests."

mkdir -p ToDoLibrary/Domain

FILE=ToDoLibrary/Domain/ToDoItem.cs

cat > $FILE << EOF
using System.Text.Json.Serialization;

namespace ToDoLibrary.Domain;

public class ToDoItem
{
    [JsonPropertyName("complete")]
    public bool? Complete { get; set; }

    [JsonPropertyName("text")]
    public string? Text { get; set; }

    [JsonPropertyName("visible")]
    public bool? Visible { get; set; }

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

FILE=ToDoLibrary/Domain/ToDoList.cs

cat > $FILE << EOF
using System.Text.Json.Serialization;

namespace ToDoLibrary.Domain;

public class ToDoList
{
    [JsonPropertyName("complete")]
    public bool? Complete { get; set; }

    [JsonPropertyName("title")]
    public string? Title { get; set; }

    [JsonPropertyName("visible")]
    public bool? Visible { get; set; }

    public static ToDoList CreateToDoList(string title) {
        title = title.Trim();

        if (string.IsNullOrEmpty(title)) {
            title = "everyday list";
        }

        return new ToDoList {
            Complete = false,
            Title = title,
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
git commit --message="Added domain code."

FILE=ToDoWebApi/appsettings.Development.json

cat > $FILE << EOF
{
  "ConnectionStrings": {  
    "DefaultConnection": "Host=localhost;Port=5432;Database=intrepion;Username=postgres;Password=password;SSL Mode=Disable;Trust Server Certificate=true;"
  },
  "JwtAudience": "$CLIENT",
  "JwtIssuer": $SERVER,
  "JwtSecretKey": "SOME_RANDOM_KEY_DO_NOT_SHARE",
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

        return await _jsonRpcService.ProcessRequest(User, json, FunctionCalls.Dictionary);
    }
}
EOF

git add $FILE
git commit --message="Added controllers."

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

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<ToDoListEntity>()
            .HasMany(toDoList => toDoList.ToDoItems)
            .WithOne(toDoItem => toDoItem.ToDoList)
            .IsRequired();

        modelBuilder.Entity<ApplicationUser>()
            .HasMany(applicationUser => applicationUser.ToDoLists)
            .WithOne(toDoList => toDoList.ApplicationUser)
            .IsRequired();
    }

    public DbSet<ToDoItemEntity>? ToDoItems { get; set; }
    public DbSet<ToDoListEntity>? ToDoLists { get; set; }
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
using System.Text.Json.Serialization;
using Microsoft.AspNetCore.Identity;

namespace ToDoWebApi.Entities;

public class ApplicationRole : IdentityRole<Guid>
{
    [JsonPropertyName("guid")]
    public Guid? Guid { get; set; }
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
using Microsoft.AspNetCore.Identity;

namespace ToDoWebApi.Entities;

public class ApplicationUser : IdentityUser<Guid>
{
    [JsonPropertyName("guid")]
    public Guid? Guid { get; set; }

    [JsonPropertyName("refresh_token")]
    public string? RefreshToken { get; set; }

    [JsonPropertyName("refresh_token_expiry_time")]
    public DateTime? RefreshTokenExpiryTime { get; set; }

    [JsonPropertyName("to_do_lists")]
    public ICollection<ToDoListEntity>? ToDoLists { get; set; }
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
    public Guid? Id { get; set; }

    [JsonPropertyName("guid")]
    public Guid? Guid { get; set; }

    [JsonPropertyName("to_do_list")]
    public ToDoListEntity? ToDoList { get; set; }
}
EOF

git add $FILE

FILE=ToDoWebApi/Entities/ToDoListEntity.cs

cat > $FILE << EOF
using System.Text.Json.Serialization;
using ToDoLibrary.Domain;

namespace ToDoWebApi.Entities;

public class ToDoListEntity : ToDoList
{
    [JsonPropertyName("application_user")]
    public ApplicationUser? ApplicationUser { get; set; }

    [JsonPropertyName("guid")]
    public Guid? Guid { get; set; }

    [JsonPropertyName("id")]
    public Guid? Id { get; set; }

    [JsonPropertyName("to_do_items")]
    public ICollection<ToDoItemEntity>? ToDoItems { get; set; }
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
    public List<Parameter>? Parameters { get; set; }
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
            "all_to_do_items", new FunctionCall
            {
                Parameters = new List<Parameter> {
                    new Parameter { Name = "guid", Kind = "string" },
                },
            }
        },
        {
            "all_to_do_lists", new FunctionCall
            {
                Parameters = new List<Parameter> {},
            }
        },
        {
            "edit_to_do_item", new FunctionCall
            {
                Parameters = new List<Parameter>
                {
                    new Parameter { Name = "complete", Kind = "boolean" },
                    new Parameter { Name = "guid", Kind = "string" },
                    new Parameter { Name = "text", Kind = "string" },
                    new Parameter { Name = "visible", Kind = "boolean" },
                },
            }
        },
        {
            "edit_to_do_list", new FunctionCall
            {
                Parameters = new List<Parameter>
                {
                    new Parameter { Name = "complete", Kind = "boolean" },
                    new Parameter { Name = "guid", Kind = "string" },
                    new Parameter { Name = "title", Kind = "string" },
                    new Parameter { Name = "visible", Kind = "boolean" },
                },
            }
        },
        {
            "login", new FunctionCall
            {
                Parameters = new List<Parameter>
                {
                    new Parameter { Name = "username", Kind = "string" },
                    new Parameter { Name = "password", Kind = "string" },
                },
            }
        },
        {
            "logout", new FunctionCall
            {
                Parameters = new List<Parameter> {},
            }
        },
        {
            "new_to_do_item", new FunctionCall
            {
                Parameters = new List<Parameter>
                {
                    new Parameter { Name = "text", Kind = "string" },
                }
            }
        },
        {
            "new_to_do_list", new FunctionCall
            {
                Parameters = new List<Parameter>
                {
                    new Parameter { Name = "title", Kind = "string" },
                }
            }
        },
        {
            "refresh", new FunctionCall
            {
                Parameters = new List<Parameter>
                {
                    new Parameter { Name = "access_token", Kind = "string" },
                    new Parameter { Name = "refresh_token", Kind = "string" },
                },
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
                },
            }
        },
        {
            "revoke", new FunctionCall
            {
                Parameters = new List<Parameter> {},
            }
        }
    };
}
EOF

git add $FILE

FILE=ToDoWebApi/JsonRpc/IJsonRpcService.cs

cat > $FILE << EOF
using System.Security.Claims;
using ToDoLibrary.JsonRpc;

namespace ToDoWebApi.JsonRpc
{
    public interface IJsonRpcService : IDisposable
    {
        Task<JsonRpcResponse> ProcessRequest(ClaimsPrincipal claimsPrincipal, string json, Dictionary<string, FunctionCall> functionCalls);
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
using System.Security.Claims;

namespace ToDoWebApi.JsonRpc;

public class JsonRpcService : IJsonRpcService, IDisposable
{
    private readonly IConfiguration _configuration;
    private readonly ApplicationDbContext _context;
    private readonly IToDoItemRepository _toDoItemRepository;
    private readonly IToDoListRepository _toDoListRepository;
    private readonly SignInManager<ApplicationUser> _signInManager;
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly IUserRepository _userRepository;

    public JsonRpcService(
        IConfiguration configuration,
        ApplicationDbContext context,
        IToDoItemRepository toDoItemRepository,
        IToDoListRepository toDoListRepository,
        SignInManager<ApplicationUser> signInManager,
        UserManager<ApplicationUser> userManager,
        IUserRepository userRepository
        )
    {
        _context = context;
        _configuration = configuration;
        _toDoItemRepository = toDoItemRepository;
        _toDoListRepository = toDoListRepository;
        _signInManager = signInManager;
        _userManager = userManager;
        _userRepository = userRepository;
    }

    public async Task<JsonRpcResponse> ProcessRequest(ClaimsPrincipal claimsPrincipal, string json, Dictionary<string, FunctionCall> functionCalls)
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

            if (functionCall.Parameters != null && functionCall.Parameters.Count > 0)
            {
                if (request.Params == null)
                {
                    return new JsonRpcResponse
                    {
                        JsonRpc = "2.0",
                        Error = new JsonRpcError
                        {
                            Code = -32602,
                            Message = "Invalid params - params is null",
                        },
                    };
                }

                JsonElement paramsElement = (JsonElement)request.Params;

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

            if (request.Method == "all_to_do_items") {
                return await _toDoItemRepository.AllToDoItemsAsync(claimsPrincipal, request);
            } else if (request.Method == "all_to_do_lists") {
                return await _toDoListRepository.AllToDoListsAsync(claimsPrincipal, request);
            } else if (request.Method == "edit_to_do_item") {
                return await _toDoItemRepository.EditToDoItemAsync(claimsPrincipal, request);
            } else if (request.Method == "edit_to_do_item") {
                return await _toDoListRepository.EditToDoListAsync(claimsPrincipal, request);
            } else if (request.Method == "login") {
                return await _userRepository.LoginAsync(request);
            } else if (request.Method == "logout") {
                return _userRepository.Logout(request);
            } else if (request.Method == "new_to_do_item") {
                return await _toDoItemRepository.NewToDoItemAsync(claimsPrincipal, request);
            } else if (request.Method == "new_to_do_list") {
                return await _toDoListRepository.NewToDoListAsync(claimsPrincipal, request);
            } else if (request.Method == "refresh") {
                return _userRepository.Refresh(request);
            } else if (request.Method == "register") {
                return await _userRepository.RegisterAsync(request);
            } else if (request.Method == "revoke") {
                return _userRepository.Revoke(claimsPrincipal, request);
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
    public string? Kind { get; set; }
    public string? Name { get; set; }
    public object? Value { get; set; }
}
EOF

git add $FILE
git commit --message="Added project json rpc files."

mkdir -p ToDoWebApi/Params

FILE=ToDoWebApi/Params/EditToDoItemParams.cs

cat > $FILE << EOF
using System.Text.Json.Serialization;

namespace ToDoWebApi.Params;

public class EditToDoItemParams
{
    [JsonPropertyName("complete")]
    public string? Complete { get; set; }

    [JsonPropertyName("guid")]
    public Guid? Guid { get; set; }

    [JsonPropertyName("text")]
    public string? Text { get; set; }

    [JsonPropertyName("visible")]
    public string? Visible { get; set; }
}
EOF

git add $FILE

FILE=ToDoWebApi/Params/EditToDoListParams.cs

cat > $FILE << EOF
using System.Text.Json.Serialization;

namespace ToDoWebApi.Params;

public class EditToDoListParams
{
    [JsonPropertyName("complete")]
    public string? Complete { get; set; }

    [JsonPropertyName("guid")]
    public Guid? Guid { get; set; }

    [JsonPropertyName("title")]
    public string? Title { get; set; }

    [JsonPropertyName("visible")]
    public string? Visible { get; set; }
}
EOF

git add $FILE

FILE=ToDoWebApi/Params/LoginParams.cs

cat > $FILE << EOF
using System.Text.Json.Serialization;

namespace ToDoWebApi.Params;

public class LoginParams
{
    [JsonPropertyName("password")]
    public string? Password { get; set; }

    [JsonPropertyName("username")]
    public string? UserName { get; set; }
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
    public string? Text { get; set; }
}
EOF

git add $FILE

FILE=ToDoWebApi/Params/NewToDoListParams.cs

cat > $FILE << EOF
using System.Text.Json.Serialization;

namespace ToDoWebApi.Params;

public class NewToDoListParams
{
    [JsonPropertyName("title")]
    public string? Title { get; set; }
}
EOF

git add $FILE

FILE=ToDoWebApi/Params/RefreshParams.cs

cat > $FILE << EOF
using System.Text.Json.Serialization;

namespace ToDoWebApi.Params;

public class RefreshParams
{
    [JsonPropertyName("access_token")]
    public string? AccessToken { get; set; }

    [JsonPropertyName("refresh_token")]
    public string? RefreshToken { get; set; }
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
    public string? Confirm { get; set; }

    [JsonPropertyName("email")]
    public string? Email { get; set; }

    [JsonPropertyName("password")]
    public string? Password { get; set; }

    [JsonPropertyName("username")]
    public string? Username { get; set; }
}
EOF

git add $FILE
git commit --message="Added params."

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
using ToDoWebApi.Token;

var builder = WebApplication.CreateBuilder(args);

var clientUrl = builder.Configuration["ClientUrl"] ??
    Environment.GetEnvironmentVariable("CLIENT_URL") ??
    throw new InvalidOperationException("CLIENT_URL not found.");

var connectionString = builder.Configuration.GetConnectionString("DefaultConnection") ??
    throw new InvalidOperationException("Connection string 'DefaultConnection' not found.");

var jwtIssuer = builder.Configuration["JwtIssuer"] ??
    Environment.GetEnvironmentVariable("JWT_ISSUER") ??
    throw new InvalidOperationException("JwtIssuer not found.");

var jwtSecretKey = builder.Configuration["JwtSecretKey"] ??
    Environment.GetEnvironmentVariable("JWT_SECRET_KEY") ??
    throw new InvalidOperationException("JwtSecretKey not found.");

var myAllowSpecificOrigins = "_myAllowSpecificOrigins";

builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseNpgsql(connectionString));

builder.Services.AddIdentity<ApplicationUser, ApplicationRole>()
    .AddEntityFrameworkStores<ApplicationDbContext>()
    .AddDefaultTokenProviders();

JwtSecurityTokenHandler.DefaultInboundClaimTypeMap.Clear();

builder.Services.AddAuthentication(opt => {
    opt.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    opt.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = jwtIssuer,
            ValidAudience = clientUrl,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSecretKey))
        };
    });

builder.Services.AddControllers();

builder.Services.AddScoped<IJsonRpcService, JsonRpcService>();
builder.Services.AddScoped<IToDoItemRepository, ToDoItemRepository>();
builder.Services.AddScoped<IToDoListRepository, ToDoListRepository>();
builder.Services.AddScoped<IUserRepository, UserRepository>();

builder.Services.AddTransient<ITokenService, TokenService>();

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

builder.Services.AddCors(options =>
{
    options.AddPolicy(myAllowSpecificOrigins,
        policy =>
        {
            policy.WithOrigins(clientUrl)
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

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.UseCors(myAllowSpecificOrigins);

app.Run();

public partial class Program {}
EOF

git add $FILE
git commit --message "Updated Program class."

mkdir -p ToDoWebApi/Repositories

FILE=ToDoWebApi/Repositories/IToDoItemRepository.cs

cat > $FILE << EOF
using System.Security.Claims;
using ToDoLibrary.JsonRpc;

namespace ToDoWebApi.Repositories
{
    public interface IToDoItemRepository : IDisposable
    {
        Task<JsonRpcResponse> AllToDoItemsAsync(ClaimsPrincipal claimsPrincipal, JsonRpcRequest request);
        Task<JsonRpcResponse> EditToDoItemAsync(ClaimsPrincipal claimsPrincipal, JsonRpcRequest request);
        Task<JsonRpcResponse> NewToDoItemAsync(ClaimsPrincipal claimsPrincipal, JsonRpcRequest request);
    }
}
EOF

git add $FILE

FILE=ToDoWebApi/Repositories/IToDoListRepository.cs

cat > $FILE << EOF
using System.Security.Claims;
using ToDoLibrary.JsonRpc;

namespace ToDoWebApi.Repositories
{
    public interface IToDoListRepository : IDisposable
    {
        Task<JsonRpcResponse> AllToDoListsAsync(ClaimsPrincipal claimsPrincipal, JsonRpcRequest request);
        Task<JsonRpcResponse> EditToDoListAsync(ClaimsPrincipal claimsPrincipal, JsonRpcRequest request);
        Task<JsonRpcResponse> NewToDoListAsync(ClaimsPrincipal claimsPrincipal, JsonRpcRequest request);
    }
}
EOF

git add $FILE

FILE=ToDoWebApi/Repositories/IUserRepository.cs

cat > $FILE << EOF
using System.Security.Claims;
using ToDoLibrary.JsonRpc;

namespace ToDoWebApi.Repositories
{
    public interface IUserRepository : IDisposable
    {
        Task<JsonRpcResponse> LoginAsync(JsonRpcRequest request);
        JsonRpcResponse Logout(JsonRpcRequest request);
        JsonRpcResponse Refresh(JsonRpcRequest request);
        Task<JsonRpcResponse> RegisterAsync(JsonRpcRequest request);
        JsonRpcResponse Revoke(ClaimsPrincipal claimsPrincipal, JsonRpcRequest request);
    }
}
EOF

git add $FILE

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
using System.Security.Claims;

namespace ToDoWebApi.Repositories;

public class ToDoItemRepository : IToDoItemRepository, IDisposable
{
    private readonly ApplicationDbContext _context;

    public ToDoItemRepository(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<JsonRpcResponse> AllToDoItemsAsync(ClaimsPrincipal claimsPrincipal, JsonRpcRequest request)
    {
        if (_context.ToDoItems == null)
        {
            return new JsonRpcResponse
            {
                Id = request.Id,
                JsonRpc = request.JsonRpc,
                Error = new JsonRpcError
                {
                    Code = -32600,
                    Message = "internal error - to do items is not found",
                },
            };
        }


        var toDoItems = await _context.ToDoItems.ToListAsync();

        return new JsonRpcResponse
        {
            Id = request.Id,
            JsonRpc = request.JsonRpc,
            Result = new AllToDoItemsResult
            {
                ToDoItems = toDoItems.Select(toDoItem => new AllToDoItemsResultToDoItem
                {
                    Complete = toDoItem.Complete,
                    Guid = toDoItem.Guid,
                    Text = toDoItem.Text,
                    Visible = toDoItem.Visible,
                }).ToList()
            },
        };
    }

    public async Task<JsonRpcResponse> EditToDoItemAsync(ClaimsPrincipal claimsPrincipal, JsonRpcRequest request)
    {
        if (request.Params == null)
        {
            return new JsonRpcResponse
            {
                Id = request.Id,
                JsonRpc = request.JsonRpc,
                Error = new JsonRpcError
                {
                    Code = -32602,
                    Message = "Invalid params - params is not found",
                },
            };
        }

        JsonElement requestParams = (JsonElement)request.Params;

        var editToDoItemParams = JsonSerializer.Deserialize<EditToDoItemParams>(requestParams.GetRawText());

        if (editToDoItemParams == null || string.IsNullOrEmpty(editToDoItemParams.Text))
        {
            return new JsonRpcResponse
            {
                Id = request.Id,
                JsonRpc = request.JsonRpc,
                Error = new JsonRpcError
                {
                    Code = -32602,
                    Message = "Invalid params - text is not found",
                },
            };
        }

        var text = editToDoItemParams.Text.Trim();

        if (_context.ToDoItems == null)
        {
            return new JsonRpcResponse
            {
                Id = request.Id,
                JsonRpc = request.JsonRpc,
                Error = new JsonRpcError
                {
                    Code = -32602,
                    Message = "internal error - to do items is not found",
                },
            };
        }

        var toDoItem = await _context.ToDoItems.Where(toDoItem => toDoItem.Text == text).FirstOrDefaultAsync();
        if (toDoItem == null) {
            return new JsonRpcResponse
            {
                Id = request.Id,
                JsonRpc = request.JsonRpc,
                Error = new JsonRpcError
                {
                    Code = -32602,
                    Message = "internal error - to do item does not exist",
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

    public async Task<JsonRpcResponse> NewToDoItemAsync(ClaimsPrincipal claimsPrincipal, JsonRpcRequest request)
    {
        if (request.Params == null)
        {
            return new JsonRpcResponse
            {
                Id = request.Id,
                JsonRpc = request.JsonRpc,
                Error = new JsonRpcError
                {
                    Code = -32602,
                    Message = "Invalid params - params is not found",
                },
            };
        }

        JsonElement requestParams = (JsonElement)request.Params;

        var newToDoItemParams = JsonSerializer.Deserialize<NewToDoItemParams>(requestParams.GetRawText());

        if (newToDoItemParams == null || string.IsNullOrEmpty(newToDoItemParams.Text))
        {
            return new JsonRpcResponse
            {
                Id = request.Id,
                JsonRpc = request.JsonRpc,
                Error = new JsonRpcError
                {
                    Code = -32602,
                    Message = "Invalid params - text is not found",
                },
            };
        }

        var text = newToDoItemParams.Text.Trim();

        if (_context.ToDoItems == null)
        {
            return new JsonRpcResponse
            {
                Id = request.Id,
                JsonRpc = request.JsonRpc,
                Error = new JsonRpcError
                {
                    Code = -32602,
                    Message = "internal error - to do items is not found",
                },
            };
        }

        var toDoItem = await _context.ToDoItems.Where(toDoItem => toDoItem.Text == text).FirstOrDefaultAsync();
        if (toDoItem != null) {
            return new JsonRpcResponse
            {
                Id = request.Id,
                JsonRpc = request.JsonRpc,
                Error = new JsonRpcError
                {
                    Code = -32602,
                    Message = "internal error - to do item is already exists",
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

FILE=ToDoWebApi/Repositories/ToDoListRepository.cs

cat > $FILE << EOF
using Microsoft.EntityFrameworkCore;
using ToDoLibrary.Domain;
using ToDoLibrary.JsonRpc;
using ToDoWebApi.Data;
using ToDoWebApi.Entities;
using ToDoWebApi.Params;
using ToDoWebApi.Results;
using System.Text.Json;
using System.Security.Claims;

namespace ToDoWebApi.Repositories;

public class ToDoListRepository : IToDoListRepository, IDisposable
{
    private readonly ApplicationDbContext _context;

    public ToDoListRepository(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<JsonRpcResponse> AllToDoListsAsync(ClaimsPrincipal claimsPrincipal, JsonRpcRequest request)
    {
        if (_context.ToDoLists == null)
        {
            return new JsonRpcResponse
            {
                Id = request.Id,
                JsonRpc = request.JsonRpc,
                Error = new JsonRpcError
                {
                    Code = -32600,
                    Message = "internal error - to do items is not found",
                },
            };
        }

        if (claimsPrincipal == null || claimsPrincipal.Identity == null || claimsPrincipal.Identity.Name == null) {
            return new JsonRpcResponse {
                Id = request.Id,
                JsonRpc = request.JsonRpc,
                Error = new JsonRpcError {
                    Code = 5,
                    Message = "Bad request - claim does not exist.",
                },
            };
        }

        var userName = claimsPrincipal.Identity.Name;
        var applicationUser = await _context.Users.Where(au => au.UserName == userName).FirstOrDefaultAsync();

        if (applicationUser == null) {
            return new JsonRpcResponse {
                Id = request.Id,
                JsonRpc = request.JsonRpc,
                Error = new JsonRpcError {
                    Code = 6,
                    Message = "Bad request - user does not exist.",
                },
            };
        }

        var toDoLists = await (from ToDoLists in _context.ToDoLists
                               join Users in _context.Users on ToDoLists.ApplicationUser.Id equals Users.Id
                               where Users.UserName == userName
                               select ToDoLists).ToListAsync();

        return new JsonRpcResponse
        {
            Id = request.Id,
            JsonRpc = request.JsonRpc,
            Result = new AllToDoListsResult
            {
                ToDoLists = toDoLists.Select(toDoList => new AllToDoListsResultToDoList
                {
                    Complete = toDoList.Complete,
                    Guid = toDoList.Guid,
                    Title = toDoList.Title,
                    Visible = toDoList.Visible,
                }).ToList()
            },
        };
    }

    public async Task<JsonRpcResponse> EditToDoListAsync(ClaimsPrincipal claimsPrincipal, JsonRpcRequest request)
    {
        if (request.Params == null)
        {
            return new JsonRpcResponse
            {
                Id = request.Id,
                JsonRpc = request.JsonRpc,
                Error = new JsonRpcError
                {
                    Code = -32602,
                    Message = "Invalid params - params is not found",
                },
            };
        }

        JsonElement requestParams = (JsonElement)request.Params;

        var editToDoListParams = JsonSerializer.Deserialize<EditToDoListParams>(requestParams.GetRawText());

        if (editToDoListParams == null || string.IsNullOrEmpty(editToDoListParams.Title))
        {
            return new JsonRpcResponse
            {
                Id = request.Id,
                JsonRpc = request.JsonRpc,
                Error = new JsonRpcError
                {
                    Code = -32602,
                    Message = "Invalid params - text is not found",
                },
            };
        }

        var title = editToDoListParams.Title.Trim();

        if (_context.ToDoLists == null)
        {
            return new JsonRpcResponse
            {
                Id = request.Id,
                JsonRpc = request.JsonRpc,
                Error = new JsonRpcError
                {
                    Code = -32602,
                    Message = "internal error - to do items is not found",
                },
            };
        }

        var toDoList = await _context.ToDoLists.Where(toDoList => toDoList.Title == title).FirstOrDefaultAsync();
        if (toDoList == null) {
            return new JsonRpcResponse
            {
                Id = request.Id,
                JsonRpc = request.JsonRpc,
                Error = new JsonRpcError
                {
                    Code = -32602,
                    Message = "internal error - to do item does not exist",
                },
            };
        }

        var message = ToDoList.CreateToDoList(title);

        toDoList = new ToDoListEntity
        {
            Title = title,
        };

        await _context.AddAsync(toDoList);
        _context.SaveChanges();

        return new JsonRpcResponse
        {
            Id = request.Id,
            JsonRpc = request.JsonRpc,
            Result = new NewToDoListResult
            {
                Title = title
            },
        };
    }

    public async Task<JsonRpcResponse> NewToDoListAsync(ClaimsPrincipal claimsPrincipal, JsonRpcRequest request)
    {
        if (request.Params == null)
        {
            return new JsonRpcResponse
            {
                Id = request.Id,
                JsonRpc = request.JsonRpc,
                Error = new JsonRpcError
                {
                    Code = -32602,
                    Message = "Invalid params - params is not found",
                },
            };
        }

        JsonElement requestParams = (JsonElement)request.Params;

        var newToDoListParams = JsonSerializer.Deserialize<NewToDoListParams>(requestParams.GetRawText());

        if (newToDoListParams == null || string.IsNullOrEmpty(newToDoListParams.Title))
        {
            return new JsonRpcResponse
            {
                Id = request.Id,
                JsonRpc = request.JsonRpc,
                Error = new JsonRpcError
                {
                    Code = -32602,
                    Message = "Invalid params - text is not found",
                },
            };
        }

        var title = newToDoListParams.Title.Trim();

        if (_context.ToDoLists == null)
        {
            return new JsonRpcResponse
            {
                Id = request.Id,
                JsonRpc = request.JsonRpc,
                Error = new JsonRpcError
                {
                    Code = -32602,
                    Message = "internal error - to do items is not found",
                },
            };
        }

        if (claimsPrincipal == null || claimsPrincipal.Identity == null || claimsPrincipal.Identity.Name == null) {
            return new JsonRpcResponse {
                Id = request.Id,
                JsonRpc = request.JsonRpc,
                Error = new JsonRpcError {
                    Code = 5,
                    Message = "Bad request - claim does not exist.",
                },
            };
        }

        var userName = claimsPrincipal.Identity.Name;
        var applicationUser = await _context.Users.Where(au => au.UserName == userName).FirstOrDefaultAsync();

        if (applicationUser == null) {
            return new JsonRpcResponse {
                Id = request.Id,
                JsonRpc = request.JsonRpc,
                Error = new JsonRpcError {
                    Code = 6,
                    Message = "Bad request - user does not exist.",
                },
            };
        }

        var toDoList = await _context.ToDoLists.Where(toDoList => toDoList.Title == title).FirstOrDefaultAsync();
        if (toDoList != null) {
            return new JsonRpcResponse
            {
                Id = request.Id,
                JsonRpc = request.JsonRpc,
                Error = new JsonRpcError
                {
                    Code = -32602,
                    Message = "internal error - to do item already exists",
                },
            };
        }

        toDoList = new ToDoListEntity
        {
            ApplicationUser = applicationUser,
            Complete = false,
            Guid = Guid.NewGuid(),
            Title = title,
            Visible = true,
        };

        await _context.AddAsync(toDoList);
        _context.SaveChanges();

        return new JsonRpcResponse
        {
            Id = request.Id,
            JsonRpc = request.JsonRpc,
            Result = new NewToDoListResult
            {
                Title = title
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

FILE=ToDoWebApi/Repositories/UserRepository.cs

cat > $FILE << EOF
using Microsoft.AspNetCore.Identity;
using ToDoLibrary.JsonRpc;
using ToDoWebApi.Data;
using ToDoWebApi.Entities;
using ToDoWebApi.Params;
using ToDoWebApi.Results;
using System.Security.Claims;
using System.Text.Json;
using ToDoWebApi.Token;

namespace ToDoWebApi.Repositories;

public class UserRepository : IUserRepository, IDisposable
{
    private readonly IConfiguration _configuration;
    private readonly ApplicationDbContext _context;
    private readonly SignInManager<ApplicationUser> _signInManager;
    private readonly ITokenService _tokenService;
    private readonly UserManager<ApplicationUser> _userManager;

    public UserRepository(
        IConfiguration configuration,
        ApplicationDbContext context,
        SignInManager<ApplicationUser> signInManager,
        ITokenService tokenService,
        UserManager<ApplicationUser> userManager
        )
    {
        _context = context;
        _configuration = configuration;
        _signInManager = signInManager;
        _tokenService = tokenService;
        _userManager = userManager;
    }
    
    public async Task<JsonRpcResponse> LoginAsync(JsonRpcRequest request)
    {
        if (request.Params == null)
        {
            return new JsonRpcResponse
            {
                JsonRpc = "2.0",
                Error = new JsonRpcError
                {
                    Code = -32602,
                    Message = "Invalid params - request.Params is not found",
                },
            };
        }

        JsonElement requestParams = (JsonElement)request.Params;

        var loginParams = JsonSerializer.Deserialize<LoginParams>(requestParams.GetRawText());
        if (loginParams == null)
        {
            return new JsonRpcResponse
            {
                JsonRpc = "2.0",
                Error = new JsonRpcError
                {
                    Code = -32602,
                    Message = "Invalid params - loginParams is not found",
                },
            };
        }

        if (loginParams.UserName == null)
        {
            return new JsonRpcResponse
            {
                JsonRpc = "2.0",
                Error = new JsonRpcError
                {
                    Code = -32602,
                    Message = "Invalid params - loginParams.UserName is not found",
                },
            };
        }

        if (loginParams.Password == null)
        {
            return new JsonRpcResponse
            {
                JsonRpc = "2.0",
                Error = new JsonRpcError
                {
                    Code = -32602,
                    Message = "Invalid params - loginParams.Password is not found",
                },
            };
        }

        var userName = loginParams.UserName.Trim();
        var password = loginParams.Password;

        var result = await _signInManager.PasswordSignInAsync(userName, password, false, false);

        if (result.Succeeded)
        {
            var clientUrl = _configuration["ClientUrl"] ??
                Environment.GetEnvironmentVariable("CLIENT_URL");

            if (clientUrl == null)
            {
                return new JsonRpcResponse
                {
                    JsonRpc = "2.0",
                    Error = new JsonRpcError
                    {
                        Code = -32600,
                        Message = "internal error - clientUrl is not found",
                    },
                };
            }

            var jwtIssuer = _configuration["JwtIssuer"] ??
                Environment.GetEnvironmentVariable("JWT_ISSUER");

            if (jwtIssuer == null)
            {
                return new JsonRpcResponse
                {
                    JsonRpc = "2.0",
                    Error = new JsonRpcError
                    {
                        Code = -32600,
                        Message = "internal error - jwtIssuer is not found",
                    },
                };
            }

            var jwtSecretKey = _configuration["JwtSecretKey"] ??
                Environment.GetEnvironmentVariable("JWT_SECRET_KEY");

            if (jwtSecretKey == null)
            {
                return new JsonRpcResponse
                {
                    JsonRpc = "2.0",
                    Error = new JsonRpcError
                    {
                        Code = -32600,
                        Message = "internal error - jwtSecretKey is not found",
                    },
                };
            }

            var user = _context.Users.FirstOrDefault(u => u.UserName == userName);

            if (user == null)
            {
                return new JsonRpcResponse
                {
                    JsonRpc = "2.0",
                    Error = new JsonRpcError
                    {
                        Code = -32600,
                        Message = "internal error - user is not found",
                    },
                };
            }

            var claims = new List<Claim>
            {
                new Claim(ClaimTypes.Name, userName),
            };
            var accessToken = _tokenService.GenerateAccessToken(claims, clientUrl, jwtIssuer, jwtSecretKey);
            var refreshToken = _tokenService.GenerateRefreshToken();

            user.RefreshToken = refreshToken;
            user.RefreshTokenExpiryTime = DateTime.Now.AddDays(7);

            return new JsonRpcResponse {
                Id = request.Id,
                JsonRpc = request.JsonRpc,
                Result = new LoginResult {
                    AccessToken = accessToken,
                    RefreshToken = refreshToken,
                    User = new LoginResultUser {
                        Guid = user.Guid,
                        UserName = user.UserName,
                    },
                },
            };
        }

        return new JsonRpcResponse {
            Id = request.Id,
            JsonRpc = request.JsonRpc,
            Error = new JsonRpcError {
                Code = 1,
                Message = "Invalid login attempt.",
                Data = result,
            },
        };
    }

    public JsonRpcResponse Logout(JsonRpcRequest request)
    {
        return new JsonRpcResponse {
            Id = request.Id,
            JsonRpc = request.JsonRpc,
        };
    }

    public JsonRpcResponse Refresh(JsonRpcRequest request)
    {
        var clientUrl = _configuration["ClientUrl"] ??
            Environment.GetEnvironmentVariable("CLIENT_URL");

        if (clientUrl == null)
        {
            return new JsonRpcResponse
            {
                JsonRpc = "2.0",
                Error = new JsonRpcError
                {
                    Code = -32600,
                    Message = "internal error - clientUrl is not found",
                },
            };
        }

        var jwtIssuer = _configuration["JwtIssuer"] ??
            Environment.GetEnvironmentVariable("JWT_ISSUER");

        if (jwtIssuer == null)
        {
            return new JsonRpcResponse
            {
                JsonRpc = "2.0",
                Error = new JsonRpcError
                {
                    Code = -32600,
                    Message = "internal error - jwtIssuer is not found",
                },
            };
        }

        var jwtSecretKey = _configuration["JwtSecretKey"] ??
            Environment.GetEnvironmentVariable("JWT_SECRET_KEY");

        if (jwtSecretKey == null)
        {
            return new JsonRpcResponse
            {
                JsonRpc = "2.0",
                Error = new JsonRpcError
                {
                    Code = -32600,
                    Message = "internal error - jwtSecretKey is not found",
                },
            };
        }

        if (request.Params == null)
        {
            return new JsonRpcResponse
            {
                JsonRpc = "2.0",
                Error = new JsonRpcError
                {
                    Code = -32602,
                    Message = "Invalid params - request.Params is not found",
                },
            };
        }

        JsonElement requestParams = (JsonElement)request.Params;

        var refreshParams = JsonSerializer.Deserialize<RefreshParams>(requestParams.GetRawText());

        if (refreshParams == null)
        {
            return new JsonRpcResponse {
                Id = request.Id,
                JsonRpc = request.JsonRpc,
                Error = new JsonRpcError {
                    Code = 2,
                    Message = "Invalid client request.",
                },
            };
        }
        
        if (refreshParams.AccessToken == null || refreshParams.RefreshToken == null)
        {
            return new JsonRpcResponse {
                Id = request.Id,
                JsonRpc = request.JsonRpc,
                Error = new JsonRpcError {
                    Code = 2,
                    Message = "Invalid client request.",
                },
            };
        }

        var accessToken = refreshParams.AccessToken;
        var refreshToken = refreshParams.RefreshToken;
        var principal = _tokenService.GetPrincipalFromExpiredToken(jwtSecretKey, accessToken);

        if (principal == null)
        {
            return new JsonRpcResponse {
                Id = request.Id,
                JsonRpc = request.JsonRpc,
                Error = new JsonRpcError {
                    Code = 2,
                    Message = "Invalid client request.",
                },
            };
        }

        if (principal.Identity == null)
        {
            return new JsonRpcResponse {
                Id = request.Id,
                JsonRpc = request.JsonRpc,
                Error = new JsonRpcError {
                    Code = 2,
                    Message = "Invalid client request.",
                },
            };
        }

        if (principal.Identity.Name == null)
        {
            return new JsonRpcResponse {
                Id = request.Id,
                JsonRpc = request.JsonRpc,
                Error = new JsonRpcError {
                    Code = 2,
                    Message = "Invalid client request.",
                },
            };
        }

        var userName = principal.Identity.Name;
        var user = _context.Users.SingleOrDefault(u => u.UserName == userName);
        if (user is null || user.RefreshToken != refreshToken || user.RefreshTokenExpiryTime <= DateTime.Now)
        {
            return new JsonRpcResponse {
                Id = request.Id,
                JsonRpc = request.JsonRpc,
                Error = new JsonRpcError {
                    Code = 2,
                    Message = "Invalid client request.",
                },
            };
        }

        var claims = new List<Claim>
        {
            new Claim(ClaimTypes.Name, userName),
        };
        var newAccessToken = _tokenService.GenerateAccessToken(claims, clientUrl, jwtIssuer, jwtSecretKey);
        var newRefreshToken = _tokenService.GenerateRefreshToken();

        user.RefreshToken = newRefreshToken;
        _context.SaveChanges();

        return new JsonRpcResponse {
            Id = request.Id,
            JsonRpc = request.JsonRpc,
            Result = new LoginResult {
                AccessToken = accessToken,
                RefreshToken = refreshToken,
            },
        };
    }

    public async Task<JsonRpcResponse> RegisterAsync(JsonRpcRequest request)
    {
        if (request.Params == null)
        {
            return new JsonRpcResponse
            {
                JsonRpc = "2.0",
                Error = new JsonRpcError
                {
                    Code = -32602,
                    Message = "Invalid params - request.Params is not found",
                },
            };
        }

        JsonElement requestParams = (JsonElement)request.Params;

        var registerParams = JsonSerializer.Deserialize<RegisterParams>(requestParams.GetRawText());

        if (registerParams == null)
        {
            return new JsonRpcResponse {
                Id = request.Id,
                JsonRpc = request.JsonRpc,
                Error = new JsonRpcError {
                    Code = 2,
                    Message = "Invalid client request.",
                },
            };
        }

        if (registerParams.Email == null || registerParams.Username == null || registerParams.Password == null || registerParams.Confirm == null)
        {
            return new JsonRpcResponse {
                Id = request.Id,
                JsonRpc = request.JsonRpc,
                Error = new JsonRpcError {
                    Code = 2,
                    Message = "Invalid client request.",
                },
            };
        }

        var confirm = registerParams.Confirm;
        var password = registerParams.Password;

        if (confirm != password) {
            return new JsonRpcResponse {
                Id = request.Id,
                JsonRpc = request.JsonRpc,
                Error = new JsonRpcError {
                    Code = 3,
                    Message = "Passwords do not match.",
                },
            };
        }

        var email = registerParams.Email.Trim();
        var userName = registerParams.Username.Trim();

        var user = new ApplicationUser {
            Email = email,
            Guid = Guid.NewGuid(),
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
                Code = 4,
                Message = "User could not be created.",
                Data = result,
            },
        };
    }

    public JsonRpcResponse Revoke(ClaimsPrincipal claimsPrincipal, JsonRpcRequest request)
    {
        if (claimsPrincipal == null || claimsPrincipal.Identity == null || claimsPrincipal.Identity.Name == null) {
            return new JsonRpcResponse {
                Id = request.Id,
                JsonRpc = request.JsonRpc,
                Error = new JsonRpcError {
                    Code = 5,
                    Message = "Bad request.",
                },
            };
        }

        var userName = claimsPrincipal.Identity.Name;
        var user = _context.Users.SingleOrDefault(u => u.UserName == userName);
        if (user == null) {
            return new JsonRpcResponse {
                Id = request.Id,
                JsonRpc = request.JsonRpc,
                Error = new JsonRpcError {
                    Code = 5,
                    Message = "Bad request.",
                },
            };
        }
        user.RefreshToken = null;
        _context.SaveChanges();
        return new JsonRpcResponse {
            Id = request.Id,
            JsonRpc = request.JsonRpc,
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

FILE=ToDoWebApi/Results/AllToDoItemsResult.cs

cat > $FILE << EOF
using System.Text.Json.Serialization;

namespace ToDoWebApi.Results;

public class AllToDoItemsResult
{
    [JsonPropertyName("to_do_items")]
    public List<AllToDoItemsResultToDoItem>? ToDoItems { get; set; }
}
EOF

git add $FILE

FILE=ToDoWebApi/Results/AllToDoItemsResultToDoItem.cs

cat > $FILE << EOF
using System.Text.Json.Serialization;

namespace ToDoWebApi.Results;

public class AllToDoItemsResultToDoItem
{
    [JsonPropertyName("complete")]
    public bool? Complete { get; set; }

    [JsonPropertyName("guid")]
    public Guid? Guid { get; set; }

    [JsonPropertyName("text")]
    public string? Text { get; set; }

    [JsonPropertyName("visible")]
    public bool? Visible { get; set; }
}
EOF

git add $FILE

FILE=ToDoWebApi/Results/AllToDoListsResult.cs

cat > $FILE << EOF
using System.Text.Json.Serialization;

namespace ToDoWebApi.Results;

public class AllToDoListsResult
{
    [JsonPropertyName("to_do_lists")]
    public List<AllToDoListsResultToDoList>? ToDoLists { get; set; }
}
EOF

git add $FILE

FILE=ToDoWebApi/Results/AllToDoListsResultToDoList.cs

cat > $FILE << EOF
using System.Text.Json.Serialization;

namespace ToDoWebApi.Results;

public class AllToDoListsResultToDoList
{
    [JsonPropertyName("complete")]
    public bool? Complete { get; set; }

    [JsonPropertyName("guid")]
    public Guid? Guid { get; set; }

    [JsonPropertyName("title")]
    public string? Title { get; set; }

    [JsonPropertyName("visible")]
    public bool? Visible { get; set; }
}
EOF

git add $FILE

FILE=ToDoWebApi/Results/LoginResult.cs

cat > $FILE << EOF
using System.Text.Json.Serialization;

namespace ToDoWebApi.Results;

public class LoginResult
{
    [JsonPropertyName("access_token")]
    public string? AccessToken { get; set; }

    [JsonPropertyName("refresh_token")]
    public string? RefreshToken { get; set; }

    [JsonPropertyName("user")]
    public LoginResultUser? User { get; set; }
}
EOF

git add $FILE

FILE=ToDoWebApi/Results/LoginResultUser.cs

cat > $FILE << EOF
using System.Text.Json.Serialization;

namespace ToDoWebApi.Results;

public class LoginResultUser
{
    [JsonPropertyName("guid")]
    public Guid? Guid { get; set; }

    [JsonPropertyName("username")]
    public string? UserName { get; set; }
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
    public string? Text { get; set; }
}
EOF

git add $FILE

FILE=ToDoWebApi/Results/NewToDoListResult.cs

cat > $FILE << EOF
using System.Text.Json.Serialization;

namespace ToDoWebApi.Results;

public class NewToDoListResult
{
    [JsonPropertyName("title")]
    public string? Title { get; set; }
}
EOF

git add $FILE

FILE=ToDoWebApi/Results/RefreshResult.cs

cat > $FILE << EOF
using System.Text.Json.Serialization;

namespace ToDoWebApi.Results;

public class RefreshResult
{
    [JsonPropertyName("access_token")]
    public string? AccessToken { get; set; }

    [JsonPropertyName("refresh_token")]
    public string? RefreshToken { get; set; }
}
EOF

git add $FILE
git commit --message="Added result files."

mkdir -p ToDoWebApi/Token

FILE=ToDoWebApi/Token/ITokenService.cs

cat > $FILE << EOF
using System.Security.Claims;

namespace ToDoWebApi.Token;

public interface ITokenService
{
    string GenerateAccessToken(IEnumerable<Claim> claims, string clientUrl, string jwtIssuer, string jwtSecretKey);
    string GenerateRefreshToken();
    ClaimsPrincipal GetPrincipalFromExpiredToken(string jwtSecretKey, string token);
}
EOF

git add $FILE

FILE=ToDoWebApi/Token/TokenService.cs

cat > $FILE << EOF
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Microsoft.IdentityModel.Tokens;

namespace ToDoWebApi.Token;

public class TokenService : ITokenService
{
    public string GenerateAccessToken(IEnumerable<Claim> claims, string clientUrl, string jwtIssuer, string jwtSecretKey)
    {
        var secretKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSecretKey));
        var signinCredentials = new SigningCredentials(secretKey, SecurityAlgorithms.HmacSha256);
        var tokeOptions = new JwtSecurityToken(
            issuer: jwtIssuer,
            audience: clientUrl,
            claims: claims,
            expires: DateTime.Now.AddMinutes(5),
            signingCredentials: signinCredentials
        );
        var tokenString = new JwtSecurityTokenHandler().WriteToken(tokeOptions);
        return tokenString;
    }
    public string GenerateRefreshToken()
    {
        var randomNumber = new byte[32];
        using (var rng = RandomNumberGenerator.Create())
        {
            rng.GetBytes(randomNumber);
            return Convert.ToBase64String(randomNumber);
        }
    }
    public ClaimsPrincipal GetPrincipalFromExpiredToken(string jwtSecretKey, string token)
    {
        var tokenValidationParameters = new TokenValidationParameters
        {
            ValidateAudience = false,
            ValidateIssuer = false,
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSecretKey)),
            ValidateLifetime = false
        };
        var tokenHandler = new JwtSecurityTokenHandler();
        SecurityToken securityToken;
        var principal = tokenHandler.ValidateToken(token, tokenValidationParameters, out securityToken);
        var jwtSecurityToken = securityToken as JwtSecurityToken;
        if (jwtSecurityToken == null || !jwtSecurityToken.Header.Alg.Equals(SecurityAlgorithms.HmacSha256, StringComparison.InvariantCultureIgnoreCase))
            throw new SecurityTokenException("Invalid token");
        return principal;
    }
}
EOF

git add $FILE
git commit --message="Added token service."
git push --force

cd ..

FRAMEWORK=$CLIENT_FRAMEWORK
REPOSITORY=$CLIENT_REPOSITORY
TEMPLATE=$CLIENT_TEMPLATE

# framework - the works
./intrepion-apps/new/common/type/full_stack/$FRAMEWORK/$TEMPLATE/the_works.sh $FRAMEWORK $REPOSITORY $SERVER $TEMPLATE

# project - add to do
cd $REPOSITORY
pwd

FILE=src/App.tsx

cat > $FILE << EOF
import { AuthProvider } from "./context/auth";
import { Routes } from "./routes";

function App() {
  return (
    <AuthProvider>
      <Routes />
    </AuthProvider>
  );
}

export default App;
EOF

git add $FILE

FILE=src/index.tsx

cat > $FILE << EOF
import React from "react";
import ReactDOM from "react-dom/client";
import App from "./App";
import reportWebVitals from "./reportWebVitals";

const root = ReactDOM.createRoot(
  document.getElementById("root") as HTMLElement
);

root.render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);

reportWebVitals();
EOF

git add $FILE
git commit --message "Updated App and index files."

mkdir -p src/components

FILE=src/components/Logout.tsx

cat > $FILE << EOF
import React, { useEffect } from "react";
import { redirect } from "react-router-dom";
import { v4 } from "uuid";

const SERVER_URL = process.env.REACT_APP_SERVER_URL ?? "http://localhost:3000";

const Logout: React.FC = () => {
  useEffect(() => {
    fetch(SERVER_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        id: v4(),
        jsonrpc: "2.0",
        method: "logout",
      }),
    })
      .then((response) => response.json())
      .then((responseJson) => {
        if (responseJson.error) {
          console.error(responseJson.error);
        } else {
          localStorage.removeItem("accessToken");
          localStorage.removeItem("refreshToken");
          redirect("/");
        }
      })
      .catch((error) => {
        console.error(error);
      });
  });

  return (
    <div>
      <h1>Logout</h1>
    </div>
  );
};

export default Logout;
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

FILE=src/components/ToDoItemForm.tsx

cat > $FILE << EOF
import React, { useEffect, useState } from "react";
import ToDoItem from "./ToDoItem";
import { v4 } from "uuid";
import { ToDoItemType } from "../types/ToDoTypes";

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
git commit --message "Added components."

mkdir -p src/context

FILE=src/context/auth.tsx

cat > $FILE << EOF
import { createContext, useContext, useEffect, useState } from "react";
import { v4 } from "uuid";
import {
  JsonRpcErrorType,
  JsonRpcResponseType,
  LoginResultType,
  NewToDoListParamsType,
} from "../types/apiTypes";
import { AuthContextData, LoginType } from "../types/authContext";
import { api } from "../lib/api";

const AuthContext = createContext<AuthContextData>({} as AuthContextData);

export const AuthProvider = ({ children }: any) => {
  const [user, setUser] = useState<object | null>(null);
  const [loading, setLoading] = useState<boolean>(true);

  useEffect(() => {
    async function loadStorageData() {
      const storageUser = localStorage.getItem("@Auth:user");
      const storageToken = localStorage.getItem("@Auth:access_token");

      if (storageUser && storageToken) {
        setUser(JSON.parse(storageUser));
      }
      setLoading(false);
    }

    loadStorageData();
  }, []);

  const allToDoLists = async (): Promise<JsonRpcResponseType> => {
    try {
      const axiosResponse = await api.post<JsonRpcResponseType>("/", {
        id: v4(),
        jsonrpc: "2.0",
        method: "all_to_do_lists",
      });

      const jsonRpcResponse = axiosResponse.data as JsonRpcResponseType;

      return jsonRpcResponse;
    } catch (err) {
      console.error(err);

      const jsonResponseType = {
        error: {
          code: -1,
          message: "Failed to get all to do lists.",
          data: err,
        },
        id: null,
        jsonrpc: "2.0",
        result: null,
      };

      return jsonResponseType;
    }
  };

  const login = async (data: LoginType): Promise<JsonRpcResponseType> => {
    try {
      const axiosResponse = await api.post<JsonRpcResponseType>("/", {
        id: v4(),
        jsonrpc: "2.0",
        method: "login",
        params: { username: data.username, password: data.password },
      });

      const jsonRpcResponse = axiosResponse.data as JsonRpcResponseType;

      const jsonRpcError = jsonRpcResponse.error as JsonRpcErrorType;
      const loginResult = jsonRpcResponse.result as LoginResultType;

      if (jsonRpcError !== null || loginResult === null) {
        console.error(jsonRpcResponse.error);

        return jsonRpcResponse;
      }

      setUser(loginResult.user);

      localStorage.setItem("@Auth:access_token", loginResult.access_token);
      localStorage.setItem("@Auth:refresh_token", loginResult.refresh_token);
      localStorage.setItem("@Auth:user", JSON.stringify(loginResult.user));

      return jsonRpcResponse;
    } catch (err) {
      console.error(err);

      const jsonResponseType = {
        error: {
          code: -1,
          message: "Login failed.",
          data: err,
        },
        id: null,
        jsonrpc: "2.0",
        result: null,
      };

      return jsonResponseType;
    }
  };

  const logout = () => {
    localStorage.clear();
    setUser(null);
  };

  const newToDoList = async (
    data: NewToDoListParamsType
  ): Promise<JsonRpcResponseType> => {
    try {
      const axiosResponse = await api.post<JsonRpcResponseType>("/", {
        id: v4(),
        jsonrpc: "2.0",
        method: "new_to_do_list",
        params: { title: data.title },
      });

      const jsonRpcResponse = axiosResponse.data as JsonRpcResponseType;

      return jsonRpcResponse;
    } catch (err) {
      console.error(err);

      const jsonResponseType = {
        error: {
          code: -1,
          message: "Failed to get all to do lists.",
          data: err,
        },
        id: null,
        jsonrpc: "2.0",
        result: null,
      };

      return jsonResponseType;
    }
  };

  return (
    <AuthContext.Provider
      value={{
        signed: !!user,
        user,
        loading,
        login,
        logout,
        allToDoLists,
        newToDoList,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  return useContext(AuthContext);
};
EOF

git add $FILE
git commit --message "Added context."

mkdir -p src/lib

FILE=src/lib/api.ts

cat > $FILE << EOF
import axios from "axios";

const SERVER_URL = process.env.REACT_APP_SERVER_URL ?? "http://localhost:3000";

export const api = axios.create({
  baseURL: SERVER_URL,
  headers: {
    "Content-Type": "application/json",
  },
});

api.interceptors.request.use(
  async (config) => {
    const token = localStorage.getItem("@Auth:access_token");
    if (token) {
      config.headers = {
        Authorization: `Bearer \${token}`,
      };
    }
    return config;
  },
  (error) => {
    Promise.reject(error);
  }
);
EOF

git add $FILE
git commit --message "Added lib."

mkdir -p src/pages

FILE=src/pages/Home.tsx

cat > $FILE << EOF
import { useAuth } from "../context/auth";
import ToDoLists from "./ToDoLists";

export const Home = () => {
  const { logout } = useAuth();

  const handleLogout = () => {
    logout();
  };

  return (
    <div>
      <button onClick={handleLogout}>Logout</button>
      <h1>Home</h1>
      <ToDoLists />
    </div>
  );
};

export default Home;
EOF

git add $FILE

FILE=src/pages/Homeless.tsx

cat > $FILE << EOF
import React from "react";
import { Link } from "react-router-dom";

const Homeless = () => {
  return (
    <>
      <h1>Homeless</h1>
      <p>
        You need to <Link to="/Login">login</Link> or{" "}
        <Link to="/Register">register</Link>.
      </p>
    </>
  );
};

export default Homeless;
EOF

git add $FILE

FILE=src/pages/Login.tsx

cat > $FILE << EOF
import React, { useState } from "react";
import { useAuth } from "../context/auth";

export const Login = () => {
  const [password, setPassword] = useState("");
  const [username, setUsername] = useState("");
  const { login } = useAuth();

  const handleLogin = async (event: React.MouseEvent<HTMLElement>) => {
    event.preventDefault();
    const response = await login({ username, password });
    if (response.error) {
      console.error(response.error);
    }
  };

  const handleChangePassword = (event: React.ChangeEvent<HTMLInputElement>) => {
    setPassword(event.target.value);
  };

  const handleChangeUsername = (event: React.ChangeEvent<HTMLInputElement>) => {
    setUsername(event.target.value);
  };

  return (
    <div>
      <h1>Login</h1>
      <label htmlFor="username">
        Username:{" "}
        <input
          id="name"
          onChange={handleChangeUsername}
          type="text"
          value={username}
        />
      </label>
      <label htmlFor="password">
        Password:{" "}
        <input
          id="password"
          onChange={handleChangePassword}
          type="password"
          value={password}
        />
      </label>
      <button onClick={handleLogin}>Login</button>
    </div>
  );
};

export default Login;
EOF

git add $FILE

FILE=src/pages/Loginless.tsx

cat > $FILE << EOF
import React from "react";
import { Navigate } from "react-router-dom";

export const Loginless = () => {
  return <Navigate to="/" />;
};

export default Loginless;
EOF

git add $FILE

FILE=src/pages/Register.tsx

cat > $FILE << EOF
import React, { useState } from "react";
import { Navigate } from "react-router-dom";
import { v4 } from "uuid";

const SERVER_URL = process.env.REACT_APP_SERVER_URL ?? "http://localhost:3000";

const Register = () => {
  const [confirm, setConfirm] = useState("");
  const [email, setEmail] = useState("");
  const [loadingRegister, setLoadingRegister] = useState(false);
  const [password, setPassword] = useState("");
  const [shouldRedirect, setShouldRedirect] = useState(false);
  const [username, setUsername] = useState("");

  const callRegister = (event: React.MouseEvent<HTMLElement>) => {
    event.preventDefault();
    setLoadingRegister(true);
    fetch(SERVER_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        id: v4(),
        jsonrpc: "2.0",
        method: "register",
        params: { confirm, email, password, username },
      }),
    })
      .then((response) => response.json())
      .then((responseJson) => {
        setLoadingRegister(false);
        if (responseJson.error) {
          console.error(responseJson.error);
        } else {
          setShouldRedirect(true);
        }
      })
      .catch((error) => {
        console.error(error);
      });
  };

  const handleChangeConfirm = (event: React.ChangeEvent<HTMLInputElement>) => {
    setConfirm(event.target.value);
  };

  const handleChangeEmail = (event: React.ChangeEvent<HTMLInputElement>) => {
    setEmail(event.target.value);
  };

  const handleChangePassword = (event: React.ChangeEvent<HTMLInputElement>) => {
    setPassword(event.target.value);
  };

  const handleChangeUsername = (event: React.ChangeEvent<HTMLInputElement>) => {
    setUsername(event.target.value);
  };

  return (
    <div>
      {!loadingRegister && shouldRedirect && <Navigate to="/Login" />}
      <h1>Register</h1>
      <label htmlFor="username">
        Username:{" "}
        <input
          id="username"
          onChange={handleChangeUsername}
          type="text"
          value={username}
        />
      </label>
      <label htmlFor="email">
        Email:{" "}
        <input
          id="email"
          onChange={handleChangeEmail}
          type="email"
          value={email}
        />
      </label>
      <label htmlFor="password">
        Password:{" "}
        <input
          id="password"
          onChange={handleChangePassword}
          type="password"
          value={password}
        />
      </label>
      <label htmlFor="confirm">
        Confirm:{" "}
        <input
          id="confirm"
          onChange={handleChangeConfirm}
          type="password"
          value={confirm}
        />
      </label>
      <button disabled={loadingRegister} onClick={callRegister}>
        Register
      </button>
    </div>
  );
};

export default Register;
EOF

git add $FILE

FILE=src/pages/ToDoLists.tsx

cat > $FILE << EOF
import React, { useEffect, useRef, useState } from "react";
import { AllToDoListsResultType } from "../types/apiTypes";
import { useAuth } from "../context/auth";

type ToDoListType = {
  guid: string;
  title: string;
};

const ToDoLists: React.FC = () => {
  const [loadingNewToDoList, setLoadingNewToDoList] = useState(false);
  const mounted = useRef(true);
  const [title, setTitle] = useState("");
  const [toDoLists, setToDoLists] = useState<ToDoListType[]>([]);
  const { allToDoLists, newToDoList } = useAuth();

  useEffect(() => {
    if (loadingNewToDoList) {
      return;
    }
    mounted.current = true;
    allToDoLists()
      .then((response) => {
        if (response.result) {
          const result = response.result;
          if (mounted.current) {
            const allToDoListsResult = result as AllToDoListsResultType;
            setToDoLists(allToDoListsResult.to_do_lists);
          }
        } else if (response.error) {
          console.error(response.error);
        }
      })
      .catch((error) => {
        console.error(error);
      });
  }, [allToDoLists, loadingNewToDoList]);

  const handleTitleChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    setTitle(event.target.value);
  };

  const callNewToDoList = (event: React.MouseEvent<HTMLElement>) => {
    event.preventDefault();
    setLoadingNewToDoList(true);
    mounted.current = true;
    newToDoList({ title })
      .then((response) => {
        if (response.result) {
          if (mounted.current) {
            setLoadingNewToDoList(false);
            setTitle("");
          }
        } else if (response.error) {
          console.error(response.error);
        }
      })
      .catch((error) => {
        console.error(error);
      });
  };

  return (
    <div>
      <h2>To Do Lists</h2>
      <label htmlFor="title">
        Title: <input type="text" value={title} onChange={handleTitleChange} />
      </label>
      {!loadingNewToDoList && (
        <button onClick={callNewToDoList}>Add New To Do List</button>
      )}
      <p>Previous To Do Lists</p>
      <ul>
        {toDoLists.map((toDoList) => (
          <li key={toDoList.guid}>
            {toDoList.guid} - {toDoList.title}
          </li>
        ))}
      </ul>
    </div>
  );
};

export default ToDoLists;
EOF

git add $FILE
git commit --message "Added pages."

mkdir -p src/routes

FILE=src/routes/index.tsx

cat > $FILE << EOF
import { useAuth } from "../context/auth";

import { SignRoutes } from "./SignRoutes";
import { ProtectRoutes } from "./ProtectRoutes";

export const Routes = () => {
  const { signed, loading } = useAuth();

  if (loading) {
    return (
      <div>
        <div>Loading...</div>
      </div>
    );
  }

  return signed ? <ProtectRoutes /> : <SignRoutes />;
};
EOF

git add $FILE

FILE=src/routes/ProtectRoutes.tsx

cat > $FILE << EOF
import { BrowserRouter, Routes, Route } from "react-router-dom";
import Home from "../pages/Home";
import Loginless from "../pages/Loginless";

export const ProtectRoutes = () => {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Home />} />
        <Route path="/Login" element={<Loginless />} />
      </Routes>
    </BrowserRouter>
  );
};
EOF

git add $FILE

FILE=src/routes/SignRoutes.tsx

cat > $FILE << EOF
import { BrowserRouter, Routes, Route } from "react-router-dom";
import Homeless from "../pages/Homeless";
import Login from "../pages/Login";
import Register from "../pages/Register";

export const SignRoutes = () => {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Homeless />} />
        <Route path="/Login" element={<Login />} />
        <Route path="/Register" element={<Register />} />
      </Routes>
    </BrowserRouter>
  );
};
EOF

git add $FILE
git commit --message "Added routes."

mkdir -p src/types

FILE=src/types/apiTypes.ts

cat > $FILE << EOF
import { ToDoListType } from "./ToDoTypes";

export type AllToDoListsParamsType = {};

export type AllToDoListsResultType = {
  to_do_lists: ToDoListType[];
};

export type JsonRpc = JsonRpcRequestType | JsonRpcResponseType;

export type JsonRpcErrorType = {
  code: number;
  message: string;
  data: any;
};

export type JsonRpcRequestType = {
  id: string;
  jsonrpc: string;
  method: string;
  params: LoginParamsType | RegisterParamsType;
};

export type JsonRpcResponseType = {
  id: null | string;
  jsonrpc: string;
  result: null | LoginResultType | RegisterResultType;
  error: null | JsonRpcErrorType;
};

export type LoginParamsType = {
  username: string;
  password: string;
};

export type LoginResultType = {
  access_token: string;
  refresh_token: string;
  user: {
    guid: string;
    username: string;
  };
};

export type NewToDoListParamsType = {
  title: string;
};

export type NewToDoListResultType = {
  guid: string;
  title: string;
};

export type RegisterParamsType = {
  confirm: string;
  email: string;
  password: string;
  username: string;
};

export type RegisterResultType = {};
EOF

git add $FILE

FILE=src/types/authContext.ts

cat > $FILE << EOF
import { JsonRpcResponseType, NewToDoListParamsType } from "./apiTypes";

export type LoginType = {
  username: string;
  password: string;
};

export interface AuthContextData {
  signed: boolean;
  user: object | null;
  loading: boolean;
  login: (data: LoginType) => Promise<JsonRpcResponseType>;
  logout: () => void;
  allToDoLists: () => Promise<JsonRpcResponseType>;
  newToDoList: (data: NewToDoListParamsType) => Promise<JsonRpcResponseType>;
}
EOF

git add $FILE

FILE=src/types/ToDoTypes.ts

cat > $FILE << EOF
export type ToDoItemType = {
  complete: boolean;
  guid: string;
  text: string;
  visible: boolean;
};

export type ToDoListType = {
  complete: boolean;
  guid: string;
  title: string;
  visible: boolean;
};
EOF

git add $FILE
git commit --message "Added types."

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
