#!/bin/bash

SCRIPT=$0
KEBOB=$1
PASCAL=$2
PROJECT=$3
REPOSITORY=$4
TEMPLATE=$5

echo " - Running $SCRIPT $KEBOB $PASCAL $PROJECT $REPOSITORY $TEMPLATE"

if [ $# -ne 5 ]; then
  echo "usage: $SCRIPT <KEBOB> <PASCAL> <PROJECT> <REPOSITORY> <TEMPLATE>"
  exit 1
fi

pushd .

cd $REPOSITORY
pwd

dotnet add $PROJECT package Npgsql.EntityFrameworkCore.PostgreSQL
git add $PROJECT
git commit --message "dotnet add $PROJECT package Npgsql.EntityFrameworkCore.PostgreSQL"

mkdir -p scripts

FILE=scripts/init_postgres.sh
cat > $FILE << EOF
#!/usr/bin/env bash

set -x
set -eo pipefail

if ! [ -x "$(command -v psql)" ]; then
    echo >&2 "Error: psql is not installed."
    exit 1
fi

DB_USER=\${POSTGRES_USER:=postgres}
DB_PASSWORD="\${POSTGRES_PASSWORD:=password}"
DB_NAME="\${POSTGRES_DB:=intrepion}"
DB_PORT="\${POSTGRES_PORT:=5432}"

if [[ -z "\${SKIP_DOCKER}" ]]
then
    sudo docker run\\
        -e POSTGRES_USER=\${DB_USER}\\
        -e POSTGRES_PASSWORD=\${DB_PASSWORD}\\
        -e POSTGRES_DB=\${DB_NAME}\\
        -p "\${DB_PORT}":5432\\
        -d postgres\\
        postgres -N 1000
fi

export PGPASSWORD="\${DB_PASSWORD}"
until psql -h "localhost" -U "\${DB_USER}" -p "\${DB_PORT}" -d "postgres" -c '\q'; do
    >&2 echo "Postgres is still unavailable - sleeping"
    sleep 1
done

>&2 echo "Postgres is up and running on port \${DB_PORT}"

DATABASE_URL=postgres://\${DB_USER}:\${DB_PASSWORD}@localhost:\${DB_PORT}/\${DB_NAME}
export DATABASE_URL
EOF
chmod +x $FILE
git add $FILE

git commit --message "Added init postgres script."

FILE=$PROJECT/appsettings.Development.json
cat > $FILE << EOF
{
  "ClientUrl": "$CLIENT",
  "ConnectionStrings": {  
    "DefaultConnection": "Host=localhost;Port=5432;Database=intrepion;Username=postgres;Password=password;SSL Mode=Disable;Trust Server Certificate=true;"
  },
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

FILE=$PROJECT/appsettings.json
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

mkdir -p $PROJECT/Data

FILE=$PROJECT/Data/ApplicationDbContext.cs
cat > $FILE << EOF
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;

namespace $PROJECT.Data;

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
    }
}
EOF
git add $FILE

FILE=$PROJECT/Data/DbInitializer.cs
cat > $FILE << EOF
namespace $PROJECT.Data;

public static class DbInitializer
{
    public static void Initialize(ApplicationDbContext context)
    {
    }
}
EOF
git add $FILE

git commit --message="Added data files."

mkdir -p $PROJECT/Entities

FILE=$PROJECT/Entities/RoleEntity.cs
cat > $FILE << EOF
using System.Text.Json.Serialization;
using Microsoft.AspNetCore.Identity;

namespace $PROJECT.Entities;

public class RoleEntity : IdentityRole<Guid>
{
    [JsonPropertyName("guid")]
    public Guid? Guid { get; set; }
}
EOF
git add $FILE

FILE=$PROJECT/Entities/UserEntity.cs
cat > $FILE << EOF
using System.Text.Json.Serialization;
using Microsoft.AspNetCore.Identity;

namespace $PROJECT.Entities;

public class UserEntity : IdentityUser<Guid>
{
    [JsonPropertyName("guid")]
    public Guid? Guid { get; set; }

    [JsonPropertyName("refresh_token")]
    public string? RefreshToken { get; set; }

    [JsonPropertyName("refresh_token_expiry_time")]
    public DateTime? RefreshTokenExpiryTime { get; set; }
}
EOF
git add $FILE

git commit --message="Added entities."

mkdir -p $PROJECT/Params

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

FILE=$PROJECT/Program.cs
cat > $FILE << EOF
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Text;
using $PROJECT.Entities;
using $PROJECT.Token;

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

builder.Services.AddIdentity<UserEntity, RoleEntity>()
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

git commit --message="Updated Program class."

mkdir -p $PROJECT/Repositories

FILE=$PROJECT/Repositories/IUserRepository.cs

cat > $FILE << EOF
using System.Security.Claims;
using ${PASCAL}JsonRpc.JsonRpc;

namespace $PROJECT.Repositories
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

FILE=$PROJECT/Repositories/UserRepository.cs
cat > $FILE << EOF
using Microsoft.AspNetCore.Identity;
using System.Security.Claims;
using System.Text.Json;
using ${PASCAL}JsonRpc.JsonRpc;
using $PROJECT.Data;
using $PROJECT.Entities;
using $PROJECT.Params;
using $PROJECT.Results;
using $PROJECT.Token;

namespace $PROJECT.Repositories;

public class UserRepository : IUserRepository, IDisposable
{
    private readonly IConfiguration _configuration;
    private readonly ApplicationDbContext _context;
    private readonly SignInManager<UserEntity> _signInManager;
    private readonly ITokenService _tokenService;
    private readonly UserManager<UserEntity> _userManager;

    public UserRepository(
        IConfiguration configuration,
        ApplicationDbContext context,
        SignInManager<UserEntity> signInManager,
        ITokenService tokenService,
        UserManager<UserEntity> userManager
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

        var user = new UserEntity {
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

mkdir -p $PROJECT/Results

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

popd

echo " - Completed $SCRIPT $KEBOB $PASCAL $PROJECT $REPOSITORY $TEMPLATE"
