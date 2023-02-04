#!/usr/bin/env bash

SCRIPT=$0

echo " - Running $SCRIPT"

killall -15 node

pushd .

cd ..
pwd

CANONICAL="intrepion"
CAPITALIZED="Intrepion"
CLIENT_URL="http://localhost:3000"
CLIENT_FRAMEWORK=typescript-react
CLIENT_TEMPLATE=typescript
CONTRACT=basic-rest
KEBOB=intrepion
PASCAL=Intrepion
SERVER_FRAMEWORK=csharp-dotnet
SERVER_TEMPLATE=webapi
SNAKE=intrepion
USER=intrepion

CLIENT_CONTRACT=$CONTRACT-client-web
SOLUTION=${PASCAL}App
SERVER_CONTRACT=$CONTRACT-server

CLIENT_REPOSITORY=$USER-$KEBOB-$CLIENT_CONTRACT-$CLIENT_FRAMEWORK-$CLIENT_TEMPLATE
PROJECT=$SOLUTION.WebApi
SERVER_REPOSITORY=$USER-$KEBOB-$SERVER_CONTRACT-$SERVER_FRAMEWORK-$SERVER_TEMPLATE

if [ ! -d "$SERVER_REPOSITORY" ]; then
  git clone git@github.com:$USER/$SERVER_REPOSITORY.git && echo "Checked out $SERVER_REPOSITORY" || exit 1
fi

cd $SERVER_REPOSITORY
pwd

git checkout main

FIRST=`git rev-list --max-parents=0 HEAD`
git reset --hard $FIRST
git clean -d --force

dotnet new gitignore
git add .gitignore
git commit --message "dotnet new gitignore"

dotnet new sln --name $SOLUTION
git add $SOLUTION.sln
git commit --message "dotnet new sln --name $SOLUTION"

dotnet new $SERVER_TEMPLATE --name $PROJECT
git add $PROJECT
git commit --message "dotnet new $SERVER_TEMPLATE --auth Individual --name $PROJECT --use-local-db"

dotnet add $PROJECT package Microsoft.AspNetCore.Cors
git add $PROJECT
git commit --message "dotnet add $PROJECT package Microsoft.AspNetCore.Cors"

dotnet add $PROJECT package Microsoft.AspNetCore.Identity.EntityFrameworkCore
git add $PROJECT
git commit --message "dotnet add $PROJECT package Microsoft.AspNetCore.Identity.EntityFrameworkCore"

dotnet add $PROJECT package Npgsql.EntityFrameworkCore.PostgreSQL
git add $PROJECT
git commit --message "dotnet add $PROJECT package Npgsql.EntityFrameworkCore.PostgreSQL"

dotnet sln $SOLUTION.sln add $PROJECT
git add $SOLUTION.sln
git commit --message "dotnet sln $SOLUTION.sln add $PROJECT"

dotnet new xunit --name $SOLUTION.Tests
git add $SOLUTION.Tests
git commit --message "dotnet new xunit --name $SOLUTION.Tests"

dotnet add $SOLUTION.Tests package FluentAssertions
git add $SOLUTION.Tests
git commit --message "dotnet add $SOLUTION.Tests package FluentAssertions"

dotnet add $SOLUTION.Tests package Microsoft.AspNetCore.Mvc.Testing
git add $SOLUTION.Tests
git commit --message "dotnet add $SOLUTION.Tests package Microsoft.AspNetCore.Mvc.Testing"

dotnet add $SOLUTION.Tests package Moq
git add $SOLUTION.Tests
git commit --message "dotnet add $SOLUTION.Tests package Moq"

dotnet sln $SOLUTION.sln add $SOLUTION.Tests
git add $SOLUTION.sln
git commit --message "dotnet sln $SOLUTION.sln add $SOLUTION.Tests"

dotnet add $SOLUTION.Tests reference $PROJECT
git add $SOLUTION.Tests
git commit --message "dotnet add $SOLUTION.Tests reference $PROJECT"

FILE=$PROJECT/Properties/launchSettings.json
SERVER_URL=$(jq '.profiles.http.applicationUrl' $FILE)

dotnet format
git add --all
git commit --message "dotnet format"

FILE=$SOLUTION.Tests/UnitTest1.cs
rm -rf $FILE
git add $FILE

FOLDER=$PROJECT/Controllers
rm -rf $FOLDER
git add $FOLDER

FILE=$PROJECT/WeatherForecast.cs
rm -rf $FILE
git add $FILE

git commit --message="Removed boilerplate."
dotnet format
git add --all
git commit --message "dotnet format"

FILE=README.md
cat << EOF >> $FILE


## Commands

### Build

\`\`\`bash
dotnet build
\`\`\`

### Test

\`\`\`bash
dotnet test
\`\`\`

### Run

\`\`\`bash
CLIENT_URL="<CLIENT_URL>" dotnet run --project $PROJECT
\`\`\`
EOF
git add $FILE

git commit -m "Added commands section to README file.";
dotnet format
git add --all
git commit --message "dotnet format"

mkdir -p .github/workflows && echo "Created .github/workflows folder" || exit 1

FILE=.github/workflows/dotnet.yml
cat > $FILE << EOF
name: .NET

on:
  push:
    branches: ["main"]
  pull_request:
    branches: ["main"]

jobs:
  build:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:12
        env:
          POSTGRES_USER: postgres
          POSTGRES_PASSWORD: password
          POSTGRES_DB: $USER
        ports:
          - 5432:5432
    steps:
      - uses: actions/checkout@v3
      - name: Setup .NET
        uses: actions/setup-dotnet@v3
        with:
          dotnet-version: 7.0.x
      - name: Restore dependencies
        run: dotnet restore
      - name: Build
        run: dotnet build --no-restore
      - name: Test
        run: dotnet test --no-build --verbosity normal
EOF
git add $FILE

FILE=README.md
cat << EOF >> $FILE

## CI/CD

[![.NET](https://github.com/$USER/$SERVER_REPOSITORY/actions/workflows/dotnet.yml/badge.svg?branch=main)](https://github.com/$USER/$SERVER_REPOSITORY/actions/workflows/dotnet.yml)
EOF
git add $FILE

git commit --message="Added GitHub Action files."
dotnet format
git add --all
git commit --message "dotnet format"

mkdir -p .do && echo "Created .do folder" || exit 1

FILE=.do/app.yaml
cat > $FILE << EOF
name: $KEBOB-$SERVER_CONTRACT
region: sfo
services:
  - dockerfile_path: Dockerfile
    github:
      branch: main
      deploy_on_push: true
      repo: $USER/$SERVER_REPOSITORY
    health_check:
      http_path: /HealthCheck
    http_port: 80
    instance_count: 1
    instance_size_slug: basic-xxs
    name: $SERVER_CONTRACT
    routes:
      - path: /
    source_dir: /
EOF
git add $FILE

FILE=.do/deploy.template.yaml
cat > $FILE << EOF
spec:
  name: $KEBOB-$SERVER_CONTRACT
  region: sfo
  services:
    - dockerfile_path: Dockerfile
      github:
        branch: main
        deploy_on_push: true
        repo: $USER/$SERVER_REPOSITORY
      health_check:
        http_path: /health_check
      http_port: 80
      instance_count: 1
      instance_size_slug: basic-xxs
      name: $SERVER_CONTRACT
      routes:
        - path: /
      source_dir: /
EOF
git add $FILE

FILE=Dockerfile
cat > $FILE << EOF
FROM mcr.microsoft.com/dotnet/sdk:7.0 AS build

WORKDIR /source

COPY $SOLUTION.sln .
COPY $SOLUTION.Tests/*.csproj ./$SOLUTION.Tests/
COPY $PROJECT/*.csproj ./$PROJECT/
RUN dotnet restore

COPY $SOLUTION.Tests/. ./$SOLUTION.Tests/
COPY $PROJECT/. ./$PROJECT/
WORKDIR /source/$PROJECT
RUN dotnet publish -c release -o /app --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:7.0
WORKDIR /app
COPY --from=build /app ./
EXPOSE 80
ENTRYPOINT ["dotnet", "$PROJECT.dll"]
EOF
git add $FILE

FILE=README.md
cat << EOF >> $FILE

## Deploy

### Digital Ocean

[![Deploy to DO](https://www.deploytodo.com/do-btn-blue.svg)](https://cloud.digitalocean.com/apps/new?repo=https://github.com/$USER/$SERVER_REPOSITORY/tree/main)
EOF
git add $FILE

mkdir -p scripts && echo "Created scripts folder" || exit 1

FILE=scripts/docker_build.sh
cat > $FILE << EOF
#!/usr/bin/env bash

sudo docker build --tag $SERVER_REPOSITORY --file Dockerfile .
EOF
chmod +x $FILE
git add $FILE

FILE=scripts/docker_container_prune.sh
cat > $FILE << EOF
#!/usr/bin/env bash

sudo docker container prune
EOF
chmod +x $FILE
git add $FILE

FILE=scripts/docker_run.sh
cat > $FILE << EOF
#!/usr/bin/env bash

sudo docker run -p 80:80 $SERVER_REPOSITORY
EOF
chmod +x $FILE
git add $FILE

FILE=scripts/docker_system_prune.sh
cat > $FILE << EOF
#!/usr/bin/env bash

sudo docker system prune --all --force
EOF
chmod +x $FILE
git add $FILE

FILE=scripts/doctl_apps_create.sh
cat > $FILE << EOF
#!/usr/bin/env bash

doctl apps create --spec .do/app.yaml
EOF
chmod +x $FILE
git add $FILE

FILE=scripts/doctl_apps_update.sh
cat > $FILE << EOF
#!/usr/bin/env bash

doctl apps update \$1 --spec .do/app.yaml
EOF
chmod +x $FILE
git add $FILE

FILE=scripts/dotnet_run.sh
cat > $FILE << EOF
#!/usr/bin/env bash

CLIENT_URL="\$1" dotnet run --project $PROJECT
EOF
chmod +x $FILE
git add $FILE

FILE=scripts/dotnet_watch.sh
cat > $FILE << EOF
#!/usr/bin/env bash

dotnet watch test --project $SOLUTION.Tests
EOF
chmod +x $FILE
git add $FILE

FILE=scripts/init_postgres.sh
cat > $FILE << EOF
#!/usr/bin/env bash

set -x
set -eo pipefail

if ! [ -x "/usr/bin/psql" ]; then
    echo >&2 "Error: psql is not installed."
    exit 1
fi

DB_USER=\${POSTGRES_USER:=postgres}
DB_PASSWORD="\${POSTGRES_PASSWORD:=password}"
DB_NAME="\${POSTGRES_DB:=$USER}"
DB_PORT="\${POSTGRES_PORT:=5432}"

if [[ -z "\${SKIP_DOCKER}" ]]
then
    sudo docker run\
        -e POSTGRES_USER=\${DB_USER}\
        -e POSTGRES_PASSWORD=\${DB_PASSWORD}\
        -e POSTGRES_DB=\${DB_NAME}\
        -p "\${DB_PORT}":5432\
        -d postgres\
        postgres -N 1000
fi

export PGPASSWORD="\${DB_PASSWORD}"
until psql -h "localhost" -U "\${DB_USER}" -p "\${DB_PORT}" -d "postgres" -c '\q'; do
    >&2 echo "Postgres is still unavailable - sleeping"
    sleep 1
done

>&2 echo "Postgres is up and running on port \${DB_PORT} - running migrations now!"

DATABASE_URL=postgres://\${DB_USER}:\${DB_PASSWORD}@localhost:\${DB_PORT}/\${DB_NAME}
export DATABASE_URL
EOF
chmod +x $FILE
git add $FILE

git commit --message="Added Digital Ocean files."
dotnet format
git add --all
git commit --message "dotnet format"

mkdir -p $SOLUTION.Tests/WebApi/HealthCheck && echo "Created $SOLUTION.Tests/WebApi/HealthCheck folder" || exit 1

FILE=$SOLUTION.Tests/WebApi/HealthCheck/TestHealthCheckController.cs
cat > $FILE << EOF
using FluentAssertions;
using Microsoft.AspNetCore.Mvc;
using $PROJECT.HealthCheck;

namespace $SOLUTION.Tests.WebApi.HealthCheck;

public class TestHealthCheckController
{
    [Fact]
    public void Get_Returns200()
    {
        // Arrange
        var controller = new HealthCheckController();

        // Act
        var actualResult = controller.Get();

        // Assert
        actualResult.Should().BeOfType<OkObjectResult>();
        var okObjectResult = (OkObjectResult)actualResult;
        okObjectResult.StatusCode.Should().Be(200);
    }
}
EOF
git add $FILE

dotnet test && exit 1 || git commit --message="red - testing the health check controller"
dotnet format
git add --all
git commit --message "dotnet format"

mkdir -p $PROJECT/HealthCheck && echo "Created $PROJECT/HealthCheck folder" || exit 1

FILE=$PROJECT/HealthCheck/HealthCheckController.cs
cat > $FILE << EOF
using Microsoft.AspNetCore.Mvc;

namespace $PROJECT.HealthCheck;

public class HealthCheckController : ControllerBase
{
    public IActionResult Get()
    {
        return Ok("");
    }
}
EOF
git add $FILE

dotnet test && git commit --message="green - testing the health check controller" || exit 1
dotnet format
git add --all
git commit --message "dotnet format"

mkdir -p $SOLUTION.Tests/Endpoints && echo "Created $SOLUTION.Tests/Endpoints folder" || exit 1

FILE=$SOLUTION.Tests/Endpoints/TestHealthCheckEndpoint.cs
cat > $FILE << EOF
using Microsoft.AspNetCore.Mvc.Testing;

namespace $SOLUTION.Tests.WebApi.Endpoints;

public class TestHealthCheckEndpoint : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> _factory;

    public TestHealthCheckEndpoint(WebApplicationFactory<Program> factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task Get_HealthCheck_EndpointReturnSuccessAndCorrectContentType()
    {
        // Arrange
        var client = _factory.CreateClient();

        // Act
        var response = await client.GetAsync("/HealthCheck");
        var actual = response.Content.Headers.ContentType?.ToString();

        // // Assert
        Assert.NotNull(response);
        response.EnsureSuccessStatusCode();
    }
}
EOF
git add $FILE

dotnet test && exit 1 || git commit --message="red - testing the health check endpoint"
dotnet format
git add --all
git commit --message "dotnet format"

FILE=$PROJECT/Program.cs
cat > $FILE << EOF
var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

app.UseAuthorization();

app.MapControllers();

app.Run();

public partial class Program { }
EOF
git add $FILE

FILE=$PROJECT/HealthCheck/HealthCheckController.cs
cat > $FILE << EOF
using Microsoft.AspNetCore.Mvc;

namespace $PROJECT.HealthCheck;

[ApiController]
[Route("[controller]")]
public class HealthCheckController : ControllerBase
{
    public IActionResult Get()
    {
        return Ok("");
    }
}
EOF
git add $FILE

dotnet test && git commit --message="green - testing the health check endpoint" || exit 1
dotnet format
git add --all
git commit --message "dotnet format"

FILE=$SOLUTION.Tests/Endpoints/TestLogInsEndpoints.cs
cat > $FILE << EOF
using System.Net;
using System.Text;
using System.Text.Json;
using FluentAssertions;
using Microsoft.AspNetCore.Mvc.Testing;
using $PROJECT.Authentication.LogIn;
using $PROJECT.Authentication.LogOut;

namespace $SOLUTION.Tests.Endpoints;

public class TestLogInsEndpoints : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> _factory;

    public TestLogInsEndpoints(WebApplicationFactory<Program> factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task LogIns_Endpoints()
    {
        // Arrange
        var client = _factory.CreateClient();
        var emptyContent = new StringContent("", Encoding.UTF8, "application/json");

        var adminMakeLogInRequest = new MakeLogInRequest
        {
            Password = "adminP@ssw0rd",
            RememberMe = true,
            UserName = "admin",
        };
        var adminMakeLogInRequestString = JsonSerializer.Serialize(adminMakeLogInRequest);
        var adminMakeLogInRequestContent = new StringContent(adminMakeLogInRequestString, Encoding.UTF8, "application/json");
        var userMakeLogInRequest = new MakeLogInRequest
        {
            Password = "userP@ssw0rd",
            RememberMe = true,
            UserName = "user",
        };
        var userMakeLogInRequestString = JsonSerializer.Serialize(userMakeLogInRequest);
        var userMakeLogInRequestContent = new StringContent(userMakeLogInRequestString, Encoding.UTF8, "application/json");

        // Act
        var response = await client.PostAsync("/LogOuts", emptyContent);

        // Assert
        Assert.NotNull(response);
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var responseContent = await response.Content.ReadAsStringAsync();
        Assert.NotNull(responseContent);
        var makeLogOutResponse = JsonSerializer.Deserialize<MakeLogOutResponse>(responseContent);
        Assert.NotNull(makeLogOutResponse);
        Assert.Null(makeLogOutResponse.UserName);

        // Act
        response = await client.PostAsync("/LogIns", userMakeLogInRequestContent);

        // Assert
        Assert.NotNull(response);
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        responseContent = await response.Content.ReadAsStringAsync();
        Assert.NotNull(responseContent);
        var makeLogInResponse = JsonSerializer.Deserialize<MakeLogInResponse>(responseContent);
        Assert.NotNull(makeLogInResponse);
        Assert.NotNull(makeLogInResponse.UserName);
        makeLogInResponse.UserName.Should().Be(userMakeLogInRequest.UserName);

        // Act
        response = await client.PostAsync("/LogOuts", emptyContent);

        // Assert
        Assert.NotNull(response);
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        responseContent = await response.Content.ReadAsStringAsync();
        Assert.NotNull(responseContent);
        makeLogOutResponse = JsonSerializer.Deserialize<MakeLogOutResponse>(responseContent);
        Assert.NotNull(makeLogOutResponse);
        Assert.NotNull(makeLogOutResponse.UserName);
        makeLogOutResponse.UserName.Should().Be(userMakeLogInRequest.UserName);

        // Act
        response = await client.PostAsync("/LogIns", adminMakeLogInRequestContent);

        // Assert
        Assert.NotNull(response);
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        responseContent = await response.Content.ReadAsStringAsync();
        Assert.NotNull(responseContent);
        makeLogInResponse = JsonSerializer.Deserialize<MakeLogInResponse>(responseContent);
        Assert.NotNull(makeLogInResponse);
        Assert.NotNull(makeLogInResponse.UserName);
        makeLogInResponse.UserName.Should().Be(adminMakeLogInRequest.UserName);

        // Act
        response = await client.PostAsync("/LogOuts", emptyContent);

        // Assert
        Assert.NotNull(response);
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        responseContent = await response.Content.ReadAsStringAsync();
        Assert.NotNull(responseContent);
        makeLogOutResponse = JsonSerializer.Deserialize<MakeLogOutResponse>(responseContent);
        Assert.NotNull(makeLogOutResponse);
        Assert.NotNull(makeLogOutResponse.UserName);
        makeLogOutResponse.UserName.Should().Be(adminMakeLogInRequest.UserName);
    }
}
EOF
git add $FILE

FILE=$SOLUTION.Tests/Endpoints/TestUsersEndpoints.cs
cat > $FILE << EOF
using System.Net;
using System.Text;
using System.Text.Json;
using FluentAssertions;
using Microsoft.AspNetCore.Mvc.Testing;
using $PROJECT.Authentication.LogIn;
using $PROJECT.Authentication.User;

namespace $SOLUTION.Tests.Endpoints;

public class TestUsersEndpoints : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> _factory;

    public TestUsersEndpoints(WebApplicationFactory<Program> factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task Users_Endpoints()
    {
        // Arrange
        var client = _factory.CreateClient();
        var emptyContent = new StringContent("", Encoding.UTF8, "application/json");

        var adminMakeLogInRequest = new MakeLogInRequest
        {
            Password = "adminP@ssw0rd",
            RememberMe = true,
            UserName = "admin",
        };
        var adminMakeLogInRequestString = JsonSerializer.Serialize(adminMakeLogInRequest);
        var adminMakeLogInRequestContent = new StringContent(adminMakeLogInRequestString, Encoding.UTF8, "application/json");

        var editUserName = Guid.NewGuid().ToString();
        var editUserRequest = new EditUserRequest
        {
            EditUserName = editUserName,
        };
        var editUserRequestString = JsonSerializer.Serialize(editUserRequest);
        var editUserRequestContent = new StringContent(editUserRequestString, Encoding.UTF8, "application/json");

        var makePassword = "makeP@ssw0rd";
        var makeUserName = "makeUserName" + String.Join("", Guid.NewGuid().ToString().Split("-"));
        var makeEmail = $"makeEmail@makeEmail.com";
        var makeUserRequest = new MakeUserRequest
        {
            Confirm = makePassword,
            Email = makeEmail,
            Password = makePassword,
            UserName = makeUserName,
        };
        var makeUserRequestString = JsonSerializer.Serialize(makeUserRequest);
        var makeUserRequestContent = new StringContent(makeUserRequestString, Encoding.UTF8, "application/json");

        var userMakeLogInRequest = new MakeLogInRequest
        {
            Password = "userP@ssw0rd",
            RememberMe = true,
            UserName = "user",
        };
        var userMakeLogInRequestString = JsonSerializer.Serialize(userMakeLogInRequest);
        var userMakeLogInRequestContent = new StringContent(userMakeLogInRequestString, Encoding.UTF8, "application/json");

        var makeMakeLogInRequest = new MakeLogInRequest
        {
            Password = makePassword,
            RememberMe = true,
            UserName = makeUserName,
        };
        var makeMakeLogInRequestString = JsonSerializer.Serialize(makeMakeLogInRequest);
        var makeMakeLogInRequestContent = new StringContent(makeMakeLogInRequestString, Encoding.UTF8, "application/json");

        // Act
        var response = await client.PostAsync("/LogOuts", emptyContent);

        // Assert
        Assert.NotNull(response);
        response.StatusCode.Should().Be(HttpStatusCode.OK);

        // Act
        response = await client.GetAsync("/Users");

        // Assert
        Assert.NotNull(response);
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        var responseContent = await response.Content.ReadAsStringAsync();
        Assert.NotNull(responseContent);
        var allUsersResponse = JsonSerializer.Deserialize<AllUsersResponse>(responseContent);
        Assert.NotNull(allUsersResponse);
        Assert.NotNull(allUsersResponse.Users);
        var previousUsersCount = allUsersResponse.Users.Count;

        // Act
        response = await client.GetAsync($"/Users/{makeUserName}");

        // Assert
        Assert.NotNull(response);
        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);

        // Act
        response = await client.PutAsync($"/Users/{makeUserName}", editUserRequestContent);

        // Assert
        Assert.NotNull(response);
        response.StatusCode.Should().Be(HttpStatusCode.NotFound);

        // Act
        response = await client.PostAsync("/Users", makeUserRequestContent);

        // Assert
        Assert.NotNull(response);
        response.StatusCode.Should().Be(HttpStatusCode.OK);

        // Act
        response = await client.PostAsync("/Users", makeUserRequestContent);

        // Assert
        Assert.NotNull(response);
        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);

        // Act
        response = await client.GetAsync("/Users");

        // Assert
        Assert.NotNull(response);
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        responseContent = await response.Content.ReadAsStringAsync();
        Assert.NotNull(responseContent);
        allUsersResponse = JsonSerializer.Deserialize<AllUsersResponse>(responseContent);
        Assert.NotNull(allUsersResponse);
        Assert.NotNull(allUsersResponse.Users);
        var nextUsersCount = allUsersResponse.Users.Count;
        Assert.Equal(previousUsersCount + 1, nextUsersCount);

        // Act
        response = await client.GetAsync($"/Users/{makeUserName}");

        // Assert
        Assert.NotNull(response);
        response.StatusCode.Should().Be(HttpStatusCode.OK);

        // Act
        response = await client.PutAsync($"/Users/{makeUserName}", editUserRequestContent);

        // Assert
        Assert.NotNull(response);
        response.StatusCode.Should().Be(HttpStatusCode.NotFound);

        // Act
        response = await client.DeleteAsync($"/Users/{makeUserName}");

        // Assert
        Assert.NotNull(response);
        response.StatusCode.Should().Be(HttpStatusCode.NotFound);

        // Act
        response = await client.PostAsync("/LogIns", adminMakeLogInRequestContent);

        // Assert
        Assert.NotNull(response);
        response.StatusCode.Should().Be(HttpStatusCode.OK);

        // Act
        response = await client.DeleteAsync($"/Users/{makeUserName}");

        // Assert
        Assert.NotNull(response);
        response.StatusCode.Should().Be(HttpStatusCode.OK);

        // Act
        response = await client.PostAsync("/LogOuts", emptyContent);

        // Assert
        Assert.NotNull(response);
        response.StatusCode.Should().Be(HttpStatusCode.OK);

        // Act
        response = await client.PostAsync("/LogIns", userMakeLogInRequestContent);

        // Assert
        Assert.NotNull(response);
        response.StatusCode.Should().Be(HttpStatusCode.OK);

        // Act
        response = await client.GetAsync("/Users");

        // Assert
        Assert.NotNull(response);
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        responseContent = await response.Content.ReadAsStringAsync();
        Assert.NotNull(responseContent);
        allUsersResponse = JsonSerializer.Deserialize<AllUsersResponse>(responseContent);
        Assert.NotNull(allUsersResponse);
        Assert.NotNull(allUsersResponse.Users);
        previousUsersCount = allUsersResponse.Users.Count;
        Assert.Equal(previousUsersCount, nextUsersCount - 1);

        // Act
        response = await client.GetAsync($"/Users/{makeUserName}");

        // Assert
        Assert.NotNull(response);
        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);

        // Act
        response = await client.PutAsync($"/Users/{makeUserName}", editUserRequestContent);

        // Assert
        Assert.NotNull(response);
        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);

        // Act
        response = await client.PostAsync("/Users", makeUserRequestContent);

        // Assert
        Assert.NotNull(response);
        response.StatusCode.Should().Be(HttpStatusCode.OK);

        // Act
        response = await client.PostAsync("/Users", makeUserRequestContent);

        // Assert
        Assert.NotNull(response);
        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);

        // Act
        response = await client.GetAsync($"/Users/{makeUserName}");

        // Assert
        Assert.NotNull(response);
        response.StatusCode.Should().Be(HttpStatusCode.OK);

        // Act
        response = await client.PutAsync($"/Users/{makeUserName}", editUserRequestContent);

        // Assert
        Assert.NotNull(response);
        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);

        // Act
        response = await client.GetAsync($"/Users/{makeUserName}");

        // Assert
        Assert.NotNull(response);
        response.StatusCode.Should().Be(HttpStatusCode.OK);

        // Act
        response = await client.GetAsync($"/Users/{editUserName}");

        // Assert
        Assert.NotNull(response);
        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);

        // Act
        response = await client.PostAsync("/LogOuts", emptyContent);

        // Assert
        Assert.NotNull(response);
        response.StatusCode.Should().Be(HttpStatusCode.OK);

        // Act
        response = await client.PostAsync("/LogIns", makeMakeLogInRequestContent);
        responseContent = await response.Content.ReadAsStringAsync();

        // Assert
        Assert.NotNull(response);
        response.StatusCode.Should().Be(HttpStatusCode.OK);

        // Act
        response = await client.GetAsync("/Users");

        // Assert
        Assert.NotNull(response);
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        responseContent = await response.Content.ReadAsStringAsync();
        Assert.NotNull(responseContent);
        allUsersResponse = JsonSerializer.Deserialize<AllUsersResponse>(responseContent);
        Assert.NotNull(allUsersResponse);
        Assert.NotNull(allUsersResponse.Users);
        nextUsersCount = allUsersResponse.Users.Count;
        Assert.Equal(previousUsersCount + 1, nextUsersCount);

        // Act
        response = await client.GetAsync($"/Users/{makeUserName}");

        // Assert
        Assert.NotNull(response);
        response.StatusCode.Should().Be(HttpStatusCode.OK);

        // Act
        response = await client.PutAsync($"/Users/{makeUserName}", editUserRequestContent);

        // Assert
        Assert.NotNull(response);
        response.StatusCode.Should().Be(HttpStatusCode.OK);

        // Act
        response = await client.GetAsync($"/Users/{makeUserName}");

        // Assert
        Assert.NotNull(response);
        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);

        // Act
        response = await client.GetAsync($"/Users/{editUserName}");

        // Assert
        Assert.NotNull(response);
        response.StatusCode.Should().Be(HttpStatusCode.OK);

        // Act
        response = await client.DeleteAsync($"/Users/{makeUserName}");

        // Assert
        Assert.NotNull(response);
        response.StatusCode.Should().Be(HttpStatusCode.NotFound);

        // Act
        response = await client.PostAsync("/LogOuts", emptyContent);

        // Assert
        Assert.NotNull(response);
        response.StatusCode.Should().Be(HttpStatusCode.OK);

        // Act
        response = await client.PostAsync("/LogIns", adminMakeLogInRequestContent);

        // Assert
        Assert.NotNull(response);
        response.StatusCode.Should().Be(HttpStatusCode.OK);

        // Act
        response = await client.DeleteAsync($"/Users/{editUserName}");

        // Assert
        Assert.NotNull(response);
        response.StatusCode.Should().Be(HttpStatusCode.OK);

        // Act
        response = await client.GetAsync("/Users");

        // Assert
        Assert.NotNull(response);
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        responseContent = await response.Content.ReadAsStringAsync();
        Assert.NotNull(responseContent);
        allUsersResponse = JsonSerializer.Deserialize<AllUsersResponse>(responseContent);
        Assert.NotNull(allUsersResponse);
        Assert.NotNull(allUsersResponse.Users);
        previousUsersCount = allUsersResponse.Users.Count;
        Assert.Equal(previousUsersCount, nextUsersCount - 1);

        // Act
        response = await client.GetAsync($"/Users/{makeUserName}");

        // Assert
        Assert.NotNull(response);
        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);

        // Act
        response = await client.PutAsync($"/Users/{makeUserName}", editUserRequestContent);

        // Assert
        Assert.NotNull(response);
        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);

        // Act
        response = await client.PostAsync("/Users", makeUserRequestContent);

        // Assert
        Assert.NotNull(response);
        response.StatusCode.Should().Be(HttpStatusCode.OK);

        // Act
        response = await client.PostAsync("/Users", makeUserRequestContent);

        // Assert
        Assert.NotNull(response);
        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);

        // Act
        response = await client.GetAsync($"/Users/{makeUserName}");

        // Assert
        Assert.NotNull(response);
        response.StatusCode.Should().Be(HttpStatusCode.OK);

        // Act
        response = await client.GetAsync("/Users");

        // Assert
        Assert.NotNull(response);
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        responseContent = await response.Content.ReadAsStringAsync();
        Assert.NotNull(responseContent);
        allUsersResponse = JsonSerializer.Deserialize<AllUsersResponse>(responseContent);
        Assert.NotNull(allUsersResponse);
        Assert.NotNull(allUsersResponse.Users);
        nextUsersCount = allUsersResponse.Users.Count;
        Assert.Equal(previousUsersCount + 1, nextUsersCount);

        // Act
        response = await client.GetAsync($"/Users/{makeUserName}");

        // Assert
        Assert.NotNull(response);
        response.StatusCode.Should().Be(HttpStatusCode.OK);

        // Act
        response = await client.PutAsync($"/Users/{makeUserName}", editUserRequestContent);

        // Assert
        Assert.NotNull(response);
        response.StatusCode.Should().Be(HttpStatusCode.OK);

        // Act
        response = await client.GetAsync($"/Users/{makeUserName}");

        // Assert
        Assert.NotNull(response);
        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);

        // Act
        response = await client.GetAsync($"/Users/{editUserName}");

        // Assert
        Assert.NotNull(response);
        response.StatusCode.Should().Be(HttpStatusCode.OK);

        // Act
        response = await client.DeleteAsync($"/Users/{makeUserName}");

        // Assert
        Assert.NotNull(response);
        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);

        // Act
        response = await client.DeleteAsync($"/Users/{editUserName}");

        // Assert
        Assert.NotNull(response);
        response.StatusCode.Should().Be(HttpStatusCode.OK);

        // Act
        response = await client.DeleteAsync($"/Users/{editUserName}");

        // Assert
        Assert.NotNull(response);
        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);

        // Act
        response = await client.PostAsync("/LogOuts", emptyContent);

        // Assert
        Assert.NotNull(response);
        response.StatusCode.Should().Be(HttpStatusCode.OK);
    }
}
EOF
git add $FILE

dotnet test && exit 1 || git commit --message="red - testing the endpoints"
dotnet format
git add --all
git commit --message "dotnet format"

mkdir -p $PROJECT/Authentication/LogIn && echo "Created $PROJECT/Authentication/LogIn folder" || exit 1

FILE=$PROJECT/Authentication/LogIn/LogInsController.cs
cat > $FILE << EOF
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using $PROJECT.Authentication.User;

namespace $PROJECT.Authentication.LogIn;

public interface ILogInsController
{
    public Task<IActionResult> MakeLogInAsync([FromBody] MakeLogInRequest makeLogInRequest);
}

[ApiController]
[Route("{controller}")]
public class LogInsController : ControllerBase, ILogInsController
{
    private readonly ILogInsRepository _loginsRepository;
    private readonly UserManager<UserEntity> _userManager;

    public LogInsController(ILogInsRepository loginsRepository, UserManager<UserEntity> userManager)
    {
        _loginsRepository = loginsRepository;
        _userManager = userManager;
    }

    [HttpPost]
    [Route("")]
    public async Task<IActionResult> MakeLogInAsync([FromBody] MakeLogInRequest makeLogInRequest)
    {
        var makeLogInResponse = await _loginsRepository.MakeLogInAsync(makeLogInRequest);

        if (makeLogInResponse is null)
        {
            return BadRequest();
        }

        return Ok(makeLogInResponse);
    }
}
EOF
git add $FILE

FILE=$PROJECT/Authentication/LogIn/LogInsRepository.cs
cat > $FILE << EOF
using Microsoft.AspNetCore.Identity;
using $PROJECT.Authentication.User;

namespace $PROJECT.Authentication.LogIn;

public interface ILogInsRepository
{
    public Task<MakeLogInResponse?> MakeLogInAsync(MakeLogInRequest makeLogInRequest);
}

public class LogInsRepository : ILogInsRepository
{
    private readonly SignInManager<UserEntity> _signInManager;

    public LogInsRepository(SignInManager<UserEntity> signInManager)
    {
        _signInManager = signInManager;
    }

    public async Task<MakeLogInResponse?> MakeLogInAsync(MakeLogInRequest makeLogInRequest)
    {
        if (makeLogInRequest is null)
        {
            return null;
        }

        if (String.IsNullOrWhiteSpace(makeLogInRequest.Password))
        {
            return null;
        }

        if (String.IsNullOrWhiteSpace(makeLogInRequest.UserName))
        {
            return null;
        }

        var result = await _signInManager.PasswordSignInAsync(makeLogInRequest.UserName, makeLogInRequest.Password, makeLogInRequest.RememberMe, false);

        if (!result.Succeeded)
        {
            return null;
        }

        return new MakeLogInResponse
        {
            UserName = makeLogInRequest.UserName,
        };
    }
}
EOF
git add $FILE

FILE=$PROJECT/Authentication/LogIn/MakeLogInRequest.cs
cat > $FILE << EOF
using System.Text.Json.Serialization;

namespace $PROJECT.Authentication.LogIn;

public class MakeLogInRequest
{
    [JsonPropertyName("password")]
    public string? Password { get; set; }

    [JsonPropertyName("rememberMe")]
    public bool RememberMe { get; set; }

    [JsonPropertyName("userName")]
    public string? UserName { get; set; }
}
EOF
git add $FILE

FILE=$PROJECT/Authentication/LogIn/MakeLogInResponse.cs
cat > $FILE << EOF
using System.Text.Json.Serialization;

namespace $PROJECT.Authentication.LogIn;

public class MakeLogInResponse
{
    [JsonPropertyName("userName")]
    public string? UserName { get; set; }
}
EOF
git add $FILE

mkdir -p $PROJECT/Authentication/LogOut && echo "Created $PROJECT/Authentication/LogOut folder" || exit 1

FILE=$PROJECT/Authentication/LogOut/LogOutsController.cs
cat > $FILE << EOF
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using $PROJECT.Authentication.User;

namespace $PROJECT.Authentication.LogOut;

public interface ILogOutsController
{
    public Task<IActionResult> MakeLogOutAsync();
}

[ApiController]
[Route("{controller}")]
public class LogOutsController : ControllerBase, ILogOutsController
{
    private readonly ILogOutsRepository _LogOutsRepository;
    private readonly UserManager<UserEntity> _userManager;

    public LogOutsController(ILogOutsRepository LogOutsRepository, UserManager<UserEntity> userManager)
    {
        _LogOutsRepository = LogOutsRepository;
        _userManager = userManager;
    }

    [HttpPost]
    [Route("")]
    public async Task<IActionResult> MakeLogOutAsync()
    {
        var currentUser = await _userManager.GetUserAsync(HttpContext.User);

        var makeLogOutResponse = await _LogOutsRepository.MakeLogOutAsync(currentUser);

        if (makeLogOutResponse is null)
        {
            return BadRequest();
        }

        return Ok(makeLogOutResponse);
    }
}
EOF
git add $FILE

FILE=$PROJECT/Authentication/LogOut/LogOutsRepository.cs
cat > $FILE << EOF
using Microsoft.AspNetCore.Identity;
using $PROJECT.Authentication.User;

namespace $PROJECT.Authentication.LogOut;

public interface ILogOutsRepository
{
    public Task<MakeLogOutResponse?> MakeLogOutAsync(UserEntity? currentUser);
}

public class LogOutsRepository : ILogOutsRepository
{
    private readonly SignInManager<UserEntity> _signInManager;

    public LogOutsRepository(SignInManager<UserEntity> signInManager)
    {
        _signInManager = signInManager;
    }

    public async Task<MakeLogOutResponse?> MakeLogOutAsync(UserEntity? currentUser)
    {
        if (currentUser is null)
        {
            return new MakeLogOutResponse();
        }

        var userName = currentUser.UserName;

        await _signInManager.SignOutAsync();

        return new MakeLogOutResponse
        {
            UserName = userName,
        };
    }
}
EOF
git add $FILE

FILE=$PROJECT/Authentication/LogOut/MakeLogOutResponse.cs
cat > $FILE << EOF
using System.Text.Json.Serialization;

namespace $PROJECT.Authentication.LogOut;

public class MakeLogOutResponse
{
    [JsonPropertyName("userName")]
    public string? UserName { get; set; }
}
EOF
git add $FILE

mkdir -p $PROJECT/Authentication/Role && echo "Created $PROJECT/Authentication/Role folder" || exit 1

FILE=$PROJECT/Authentication/Role/RoleEntity.cs
cat > $FILE << EOF
using Microsoft.AspNetCore.Identity;

namespace $PROJECT.Authentication.Role;

public class RoleEntity : IdentityRole<Guid>
{
}
EOF
git add $FILE

mkdir -p $PROJECT/Authentication/User && echo "Created $PROJECT/Authentication/User folder" || exit 1

FILE=$PROJECT/Authentication/User/AllUsersResponse.cs
cat > $FILE << EOF
using System.Text.Json.Serialization;

namespace $PROJECT.Authentication.User;

public class AllUsersResponseUser
{
    [JsonPropertyName("userName")]
    public string? UserName { get; set; }
}

public class AllUsersResponse
{
    [JsonPropertyName("users")]
    public List<AllUsersResponseUser>? Users { get; set; }
}
EOF
git add $FILE

FILE=$PROJECT/Authentication/User/EditUserRequest.cs
cat > $FILE << EOF
using System.Text.Json.Serialization;

namespace $PROJECT.Authentication.User;

public class EditUserRequest
{
    [JsonPropertyName("currentPassword")]
    public string? CurrentPassword { get; set; }

    [JsonPropertyName("editConfirm")]
    public string? EditConfirm { get; set; }

    [JsonPropertyName("editEmail")]
    public string? EditEmail { get; set; }

    [JsonPropertyName("editPassword")]
    public string? EditPassword { get; set; }

    [JsonPropertyName("editUserName")]
    public string? EditUserName { get; set; }
}
EOF
git add $FILE

FILE=$PROJECT/Authentication/User/EditUserResponse.cs
cat > $FILE << EOF
using System.Text.Json.Serialization;

namespace $PROJECT.Authentication.User;

public class EditUserResponse
{
    [JsonPropertyName("userName")]
    public string? UserName { get; set; }
}
EOF
git add $FILE

FILE=$PROJECT/Authentication/User/MakeUserRequest.cs
cat > $FILE << EOF
using System.Text.Json.Serialization;

namespace $PROJECT.Authentication.User;

public class MakeUserRequest
{
    [JsonPropertyName("confirm")]
    public string? Confirm { get; set; }

    [JsonPropertyName("email")]
    public string? Email { get; set; }

    [JsonPropertyName("password")]
    public string? Password { get; set; }

    [JsonPropertyName("userName")]
    public string? UserName { get; set; }
}
EOF
git add $FILE

FILE=$PROJECT/Authentication/User/MakeUserResponse.cs
cat > $FILE << EOF
using System.Text.Json.Serialization;

namespace $PROJECT.Authentication.User;

public class MakeUserResponse
{
    [JsonPropertyName("userName")]
    public string? UserName { get; set; }
}
EOF
git add $FILE

FILE=$PROJECT/Authentication/User/RemoveUserResponse.cs
cat > $FILE << EOF
namespace $PROJECT.Authentication.User;

public class RemoveUserResponse
{
}
EOF
git add $FILE

FILE=$PROJECT/Authentication/User/UserEntity.cs
cat > $FILE << EOF
using Microsoft.AspNetCore.Identity;

namespace $PROJECT.Authentication.User;

public class UserEntity : IdentityUser<Guid>
{
}
EOF
git add $FILE

FILE=$PROJECT/Authentication/User/UsersController.cs
cat > $FILE << EOF
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;

namespace $PROJECT.Authentication.User;

public interface IUsersController
{
    public Task<IActionResult> AllUsersAsync();
    public Task<IActionResult> EditUserAsync(string userName, [FromBody] EditUserRequest editUserRequest);
    public Task<IActionResult> MakeUserAsync([FromBody] MakeUserRequest makeUserRequest);
    public Task<IActionResult> RemoveUserAsync(string userName);
    public Task<IActionResult> ViewUserAsync(string userName);
}

[ApiController]
[Route("{controller}")]
public class UsersController : ControllerBase, IUsersController
{
    private readonly UserManager<UserEntity> _userManager;
    private readonly IUsersRepository _usersRepository;

    public UsersController(UserManager<UserEntity> userManager, IUsersRepository usersRepository)
    {
        _userManager = userManager;
        _usersRepository = usersRepository;
    }

    [HttpGet]
    [Route("")]
    public async Task<IActionResult> AllUsersAsync()
    {
        var allUsersResponse = await _usersRepository.AllUsersAsync();

        if (allUsersResponse is null)
        {
            return BadRequest();
        }

        return Ok(allUsersResponse);
    }

    [Authorize]
    [HttpPut]
    [Route("{userName}")]
    public async Task<IActionResult> EditUserAsync(string userName, [FromBody] EditUserRequest editUserRequest)
    {
        var currentUser = await _userManager.GetUserAsync(HttpContext.User);

        var editUserResponse = await _usersRepository.EditUserAsync(currentUser, userName, editUserRequest);

        if (editUserResponse is null)
        {
            return BadRequest();
        }

        return Ok(editUserResponse);
    }

    [AllowAnonymous]
    [HttpPost]
    [Route("")]
    public async Task<IActionResult> MakeUserAsync([FromBody] MakeUserRequest makeUserRequest)
    {
        var makeUserResponse = await _usersRepository.MakeUserAsync(makeUserRequest);

        if (makeUserResponse is null)
        {
            return BadRequest();
        }

        return Ok(makeUserResponse);
    }

    [Authorize(Roles = "Admin")]
    [HttpDelete]
    [Route("{userName}")]
    public async Task<IActionResult> RemoveUserAsync(string userName)
    {
        var removeUserResponse = await _usersRepository.RemoveUserAsync(userName);

        if (removeUserResponse is null)
        {
            return BadRequest();
        }

        return Ok(removeUserResponse);
    }

    [HttpGet]
    [Route("{userName}")]
    public async Task<IActionResult> ViewUserAsync(string userName)
    {
        var viewUserResponse = await _usersRepository.ViewUserAsync(userName);

        if (viewUserResponse is null)
        {
            return BadRequest();
        }

        return Ok(viewUserResponse);
    }
}
EOF
git add $FILE

FILE=$PROJECT/Authentication/User/UsersRepository.cs
cat > $FILE << EOF
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using $PROJECT.Authentication.Role;
using $PROJECT.Database;

namespace $PROJECT.Authentication.User;

public interface IUsersRepository
{
    public Task<AllUsersResponse?> AllUsersAsync();
    public Task<EditUserResponse?> EditUserAsync(UserEntity? currentUser, string userName, EditUserRequest editUserRequest);
    public Task<MakeUserResponse?> MakeUserAsync(MakeUserRequest makeUserRequest);
    public Task<RemoveUserResponse?> RemoveUserAsync(string userName);
    public Task<ViewUserResponse?> ViewUserAsync(string userName);
}

public class UsersRepository : IUsersRepository
{
    private readonly ApplicationDatabaseContext _applicationDatabaseContext;
    private readonly RoleManager<RoleEntity> _roleManager;
    private readonly UserManager<UserEntity> _userManager;

    public UsersRepository(
        ApplicationDatabaseContext applicationDatabaseContext,
        RoleManager<RoleEntity> roleManager,
        UserManager<UserEntity> userManager)
    {
        _applicationDatabaseContext = applicationDatabaseContext;
        _roleManager = roleManager;
        _userManager = userManager;
    }

    public async Task<AllUsersResponse?> AllUsersAsync()
    {
        var data = await _applicationDatabaseContext.Users.Select(user => new AllUsersResponseUser()
        {
            UserName = user.UserName,
        }).ToListAsync();

        if (data is null)
        {
            return null;
        }

        return new AllUsersResponse()
        {
            Users = data,
        };
    }

    public async Task<EditUserResponse?> EditUserAsync(UserEntity? currentUser, string userName, EditUserRequest editUserRequest)
    {
        if (userName is null)
        {
            return null;
        }

        if (editUserRequest is null)
        {
            return null;
        }

        userName = userName.Trim();

        var userEntity = await _userManager.FindByNameAsync(userName);

        if (userEntity is null)
        {
            return null;
        }

        if (currentUser is null)
        {
            return null;
        }

        if (currentUser.UserName is null)
        {
            return null;
        }

        if (!currentUser.UserName.Equals(userName))
        {
            if (!_userManager.IsInRoleAsync(currentUser, "Admin").Result)
            {
                return null;
            }
        }

        if (!(String.IsNullOrWhiteSpace(editUserRequest.CurrentPassword)
            || String.IsNullOrWhiteSpace(editUserRequest.EditConfirm)
            || String.IsNullOrWhiteSpace(editUserRequest.EditPassword)))
        {
            if (!editUserRequest.EditConfirm.Equals(editUserRequest.EditPassword))
            {
                return null;
            }

            await _userManager.ChangePasswordAsync(userEntity, editUserRequest.CurrentPassword, editUserRequest.EditPassword);
        }

        if (!String.IsNullOrWhiteSpace(editUserRequest.EditEmail))
        {
            editUserRequest.EditEmail = editUserRequest.EditEmail.Trim();
            userEntity.Email = editUserRequest.EditEmail;
        }

        if (!String.IsNullOrWhiteSpace(editUserRequest.EditUserName))
        {
            editUserRequest.EditUserName = editUserRequest.EditUserName.Trim();
            userEntity.UserName = editUserRequest.EditUserName;
        }

        var result = await _userManager.UpdateAsync(userEntity);

        if (!result.Succeeded)
        {
            return null;
        }

        return new EditUserResponse
        {
            UserName = userEntity.UserName,
        };
    }

    public async Task<MakeUserResponse?> MakeUserAsync(MakeUserRequest makeUserRequest)
    {
        if (makeUserRequest is null)
        {
            return null;
        }

        if (String.IsNullOrWhiteSpace(makeUserRequest.Confirm))
        {
            return null;
        }

        makeUserRequest.Confirm = makeUserRequest.Confirm.Trim();

        if (String.IsNullOrWhiteSpace(makeUserRequest.Email))
        {
            return null;
        }

        makeUserRequest.Email = makeUserRequest.Email.Trim();

        if (String.IsNullOrWhiteSpace(makeUserRequest.Password))
        {
            return null;
        }

        makeUserRequest.Password = makeUserRequest.Password.Trim();

        if (String.IsNullOrWhiteSpace(makeUserRequest.UserName))
        {
            return null;
        }

        makeUserRequest.UserName = makeUserRequest.UserName.Trim();

        if (!makeUserRequest.Confirm.Equals(makeUserRequest.Password))
        {
            return null;
        }

        var user = new UserEntity
        {
            Email = makeUserRequest.Email,
            UserName = makeUserRequest.UserName,
        };

        var result = await _userManager.CreateAsync(user, makeUserRequest.Password);

        if (!result.Succeeded)
        {
            return null;
        }

        var regularRole = await _roleManager.FindByNameAsync("Regular");

        if (regularRole is null)
        {
            return null;
        }

        if (regularRole.Name is null)
        {
            return null;
        }

        await _userManager.AddToRolesAsync(user, new List<string> { regularRole.Name });

        return new MakeUserResponse
        {
            UserName = user.UserName,
        };
    }

    public async Task<RemoveUserResponse?> RemoveUserAsync(string userName)
    {
        if (String.IsNullOrWhiteSpace(userName))
        {
            return null;
        }

        var userEntity = await _userManager.FindByNameAsync(userName);

        if (userEntity is null)
        {
            return null;
        }

        var result = await _userManager.DeleteAsync(userEntity);

        if (!result.Succeeded)
        {
            return null;
        }

        return new RemoveUserResponse
        {
        };
    }

    public async Task<ViewUserResponse?> ViewUserAsync(string userName)
    {
        if (String.IsNullOrWhiteSpace(userName))
        {
            return null;
        }

        var userEntity = await _applicationDatabaseContext.Users.SingleOrDefaultAsync(user => user.UserName == userName);

        if (userEntity is null)
        {
            return null;
        }

        return new ViewUserResponse
        {
            UserName = userEntity.UserName,
        };
    }
}
EOF
git add $FILE

FILE=$PROJECT/Authentication/User/ViewUserResponse.cs
cat > $FILE << EOF
using System.Text.Json.Serialization;

namespace $PROJECT.Authentication.User;

public class ViewUserResponse
{
    [JsonPropertyName("userName")]
    public string? UserName { get; set; }
}
EOF
git add $FILE

mkdir -p $PROJECT/Authentication/UserRole && echo "Created $PROJECT/Authentication/UserRole folder" || exit 1

FILE=$PROJECT/Authentication/UserRole/UserRoleEntity.cs
cat > $FILE << EOF
using Microsoft.AspNetCore.Identity;

namespace $PROJECT.Authentication.UserRole;

public class UserRoleEntity : IdentityUserRole<Guid>
{
}
EOF
git add $FILE

mkdir -p $PROJECT/Database && echo "Created $PROJECT/Database folder" || exit 1

FILE=$PROJECT/Database/ApplicationDatabaseContext.cs
cat > $FILE << EOF
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using IntrepionApp.WebApi.Authentication.Role;
using IntrepionApp.WebApi.Authentication.User;
using IntrepionApp.WebApi.Authentication.UserRole;

namespace IntrepionApp.WebApi.Database;

public class ApplicationDatabaseContext : IdentityDbContext<UserEntity, RoleEntity, Guid>
{
    public ApplicationDatabaseContext(DbContextOptions<ApplicationDatabaseContext> options) : base(options)
    {
        Database.EnsureCreated();
    }

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);

        var adminRole = new RoleEntity
        {
            Id = Guid.NewGuid(),
            Name = "Admin",
            NormalizedName = "ADMIN"
        };

        var regularRole = new RoleEntity
        {
            Id = Guid.NewGuid(),
            Name = "Regular",
            NormalizedName = "REGULAR"
        };

        builder.Entity<RoleEntity>().HasData(new List<RoleEntity>
        {
            adminRole,
            regularRole,
        });

        var hasher = new PasswordHasher<UserEntity>();

        var adminUser = new UserEntity
        {
            ConcurrencyStamp = Guid.NewGuid().ToString(),
            Email = "$USER@gmail.com",
            Id = Guid.NewGuid(),
            SecurityStamp = Guid.NewGuid().ToString(),
            UserName = "admin",
        };

        adminUser.NormalizedEmail = adminUser.Email.ToUpper();
        adminUser.NormalizedUserName = adminUser.UserName.ToUpper();
        adminUser.PasswordHash = hasher.HashPassword(adminUser, "adminP@ssw0rd");

        var ${USER}User = new UserEntity
        {
            ConcurrencyStamp = Guid.NewGuid().ToString(),
            Email = "$USER@gmail.com",
            Id = Guid.NewGuid(),
            SecurityStamp = Guid.NewGuid().ToString(),
            UserName = "$USER",
        };

        ${USER}User.NormalizedEmail = ${USER}User.Email.ToUpper();
        ${USER}User.NormalizedUserName = ${USER}User.UserName.ToUpper();
        ${USER}User.PasswordHash = hasher.HashPassword(${USER}User, "${USER}P@ssw0rd");

        var regularUser = new UserEntity
        {
            ConcurrencyStamp = Guid.NewGuid().ToString(),
            Email = "$USER@gmail.com",
            Id = Guid.NewGuid(),
            SecurityStamp = Guid.NewGuid().ToString(),
            UserName = "regular",
        };

        regularUser.NormalizedEmail = regularUser.Email.ToUpper();
        regularUser.NormalizedUserName = regularUser.UserName.ToUpper();
        regularUser.PasswordHash = hasher.HashPassword(regularUser, "regularP@ssw0rd");

        var userUser = new UserEntity
        {
            ConcurrencyStamp = Guid.NewGuid().ToString(),
            Email = "$USER@gmail.com",
            Id = Guid.NewGuid(),
            SecurityStamp = Guid.NewGuid().ToString(),
            UserName = "user",
        };

        userUser.NormalizedEmail = userUser.Email.ToUpper();
        userUser.NormalizedUserName = userUser.UserName.ToUpper();
        userUser.PasswordHash = hasher.HashPassword(userUser, "userP@ssw0rd");

        builder.Entity<UserEntity>().HasData(
            adminUser,
            ${USER}User,
            regularUser,
            userUser
        );

        builder.Entity<UserRoleEntity>().HasData(
            new UserRoleEntity
            {
                RoleId = adminRole.Id,
                UserId = adminUser.Id,
            },
            new UserRoleEntity
            {
                RoleId = regularRole.Id,
                UserId = regularUser.Id,
            },
            new UserRoleEntity
            {
                RoleId = regularRole.Id,
                UserId = userUser.Id,
            }
        );
    }
}
EOF
git add $FILE

FILE=$PROJECT/appsettings.Development.json
cat > $FILE << EOF
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=localhost;Port=5432;Database=$USER;Username=postgres;Password=password;SSL Mode=Disable;Trust Server Certificate=true;Include Error Detail=true;"
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

FILE=$PROJECT/Program.cs
cat > $FILE << EOF
using Microsoft.EntityFrameworkCore;
using $PROJECT.Authentication.LogIn;
using $PROJECT.Authentication.LogOut;
using $PROJECT.Authentication.Role;
using $PROJECT.Authentication.User;
using $PROJECT.Database;

var builder = WebApplication.CreateBuilder(args);

var connectionString = builder.Configuration.GetConnectionString("DefaultConnection") ??
    throw new InvalidOperationException("Connection string 'DefaultConnection' not found.");

builder.Services.AddDbContext<ApplicationDatabaseContext>(options =>
    options.UseNpgsql(connectionString));

builder.Services.AddIdentity<UserEntity, RoleEntity>()
    .AddEntityFrameworkStores<ApplicationDatabaseContext>();

builder.Services.AddControllers();

builder.Services.AddScoped<ILogInsRepository, LogInsRepository>();
builder.Services.AddScoped<ILogOutsRepository, LogOutsRepository>();
builder.Services.AddScoped<IUsersRepository, UsersRepository>();

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var ClientUrl = Environment.GetEnvironmentVariable("CLIENT_URL") ?? $SERVER_URL;

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

app.UseHttpsRedirection();

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();
app.UseCors(MyAllowSpecificOrigins);

app.Run();

public partial class Program { }
EOF
git add $FILE

dotnet test && git commit --message="green - testing the endpoints" || exit 1
dotnet format
git add --all
git commit --message "dotnet format"

git push --force

cd ..

if [ ! -d "$CLIENT_REPOSITORY" ]; then
  git clone git@github.com:$USER/$CLIENT_REPOSITORY.git || exit 1;
fi

cd $CLIENT_REPOSITORY
pwd

git checkout main

FIRST=`git rev-list --max-parents=0 HEAD`
git reset --hard $FIRST
git clean -d --force

npx create-react-app . --template $CLIENT_TEMPLATE
git add --all
git commit --message "npx create-react-app . --template $CLIENT_TEMPLATE"

mv README.old.md README.md
git add README.old.md README.md
git commit --message "mv README.old.md README.md"

npm install cypress --save-dev
git add --all
git commit --message "npm install cypress --save-dev"

FILE=.gitignore
cat << EOF >> $FILE

# cypress
/cypress/screenshots
/cypress/videos
EOF
git add $FILE
git commit --message "Added cypress to .gitignore."

npm install prettier --save-dev --save-exact
git add --all
git commit --message "npm install prettier --save-dev --save-exact"

echo {}> .prettierrc.json
git add .prettierrc.json
git commit --message "echo {}> .prettierrc.json"

cp .gitignore .prettierignore
git add .prettierignore
git commit --message "cp .gitignore .prettierignore"

npx prettier --write .
git add --all
git commit --message "npx prettier --write ."

npm install @types/uuid
git add --all
git commit --message "npm install @types/uuid"

npm install axios
git add --all
git commit --message "npm install axios"

FILE=package.json
sed -i 's/"test": "react-scripts test"/"test": "react-scripts test --transformIgnorePatterns \\"node_modules\/(?!axios)\/\\""/g' $FILE
git add $FILE
git commit --message '"test": "react-scripts test --transformIgnorePatterns \"node_modules/(?!axios)/\"",'

npm install react-bootstrap --save
git add --all
git commit --message "npm install react-bootstrap --save"

npm install react-ga4 --save
git add --all
git commit --message "npm install react-ga4 --save"

npm install react-router-dom --save
git add --all
git commit --message "npm install react-router-dom --save"

npm install uuid --save
git add --all
git commit --message "npm install uuid --save"

FILE=src/App.css
rm -rf $FILE
git add $FILE

FILE=src/App.test.tsx
rm -rf $FILE
git add $FILE

FILE=src/App.tsx
cat > $FILE << EOF
import React from "react";

function App() {
  return <></>;
}

export default App;
EOF
git add $FILE

FILE=src/index.css
rm -rf $FILE
git add $FILE

FILE=src/index.tsx
cat > $FILE << EOF
import { StrictMode } from "react";
import ReactDOM from "react-dom/client";
import App from "./App";
import reportWebVitals from "./reportWebVitals";

const root = ReactDOM.createRoot(
  document.getElementById("root") as HTMLElement
);
root.render(
  <StrictMode>
    <App />
  </StrictMode>
);

reportWebVitals();
EOF
git add $FILE

FILE=src/logo.svg
rm -rf $FILE
git add $FILE

git commit --message="Removed boilerplate."
npx prettier --write .
git add --all
git commit --message "npx prettier --write ."

FILE=README.md
cat << EOF >> $FILE

## Commands

### Install

\`\`\`bash
npm install
\`\`\`

### Test

\`\`\`bash
npm test
\`\`\`

### Initialize Database

\`\`\`bash
./scripts/init_postgres.sh
\`\`\`

### Run

\`\`\`bash
REACT_APP_SERVER_URL="<SERVER_URL>" npm start
\`\`\`
EOF
git add README.md

git commit -m "Added commands section to README file.";
npx prettier --write .
git add --all
git commit --message "npx prettier --write ."

mkdir -p .github/workflows && echo "Created .github/workflows folder" || exit 1

FILE=.github/workflows/node.js.yml
cat > $FILE << EOF
name: Node.js CI

on:
  push:
    branches: ["main"]
  pull_request:
    branches: ["main"]

jobs:
  build:
    runs-on: ubuntu-latest

    strategy:
      matrix:
        node-version: [14.x, 16.x, 18.x]

    steps:
      - uses: actions/checkout@v3
      - name: Use Node.js \${{ matrix.node-version }}
        uses: actions/setup-node@v3
        with:
          node-version: \${{ matrix.node-version }}
          cache: "npm"
      - run: npm install
      - run: npm run build --if-present
      - run: npm test
      - name: Cypress
        uses: cypress-io/github-action@v5
        with:
          build: npm run build
          start: npm start
EOF
git add $FILE

FILE=README.md
cat << EOF >> $FILE

## CI/CD

[![.NET](https://github.com/$USER/$CLIENT_REPOSITORY/actions/workflows/node.js.yml/badge.svg?branch=main)](https://github.com/$USER/$CLIENT_REPOSITORY/actions/workflows/node.js.yml)
EOF
git add $FILE

git commit --message="Added GitHub Action files."
npx prettier --write .
git add --all
git commit --message "npx prettier --write ."

mkdir -p .do && echo "Created .do folder" || exit 1

FILE=.do/app.yaml
cat > $FILE << EOF
name: $KEBOB-$CLIENT_CONTRACT
region: sfo
static_sites:
  - build_command: npm run build
    catchall_document: index.html
    environment_slug: node-js
    github:
      branch: main
      deploy_on_push: true
      repo: $USER/$CLIENT_REPOSITORY
    name: $CLIENT_CONTRACT
    routes:
      - path: /
    source_dir: /
EOF
git add $FILE

FILE=.do/deploy.template.yaml
cat > $FILE << EOF
spec:
  name: $KEBOB-$CLIENT_CONTRACT
  region: sfo
  static_sites:
    - build_command: npm run build
      catchall_document: index.html
      environment_slug: node-js
      github:
        branch: main
        deploy_on_push: true
        repo: $USER/$CLIENT_REPOSITORY
      name: $CLIENT_CONTRACT
      routes:
        - path: /
      source_dir: /
EOF
git add $FILE

FILE=README.md
cat << EOF >> $FILE

## Deploy

### Digital Ocean

[![Deploy to DO](https://www.deploytodo.com/do-btn-blue.svg)](https://cloud.digitalocean.com/apps/new?repo=https://github.com/$USER/$CLIENT_REPOSITORY/tree/main)
EOF
git add $FILE

mkdir -p scripts && echo "Created scripts folder" || exit 1

FILE=scripts/doctl_apps_create.sh
cat > $FILE << EOF
#!/usr/bin/env bash

doctl apps create --spec .do/app.yaml
EOF
chmod +x $FILE
git add $FILE

FILE=scripts/doctl_apps_update.sh
cat > $FILE << EOF
#!/usr/bin/env bash

doctl apps update \$1 --spec .do/app.yaml
EOF
chmod +x $FILE
git add $FILE

FILE=scripts/npm_start.sh
cat > $FILE << EOF
#!/usr/bin/env bash

REACT_APP_SERVER_URL=$SERVER_URL npm start
EOF
chmod +x $FILE
git add $FILE

git commit --message="Added Digital Ocean files."
npx prettier --write .
git add --all
git commit --message "npx prettier --write ."

REACT_APP_SERVER_URL=$SERVER_URL npm start &

FILE=cypress.config.ts
cat > $FILE << EOF
import { defineConfig } from "cypress";

export default defineConfig({
  e2e: {
    setupNodeEvents(on, config) {},
  },
});
EOF
git add $FILE

mkdir -p cypress/support && echo "Created cypress/support folder" || exit 1

FILE=cypress/support/e2e.ts
touch $FILE
git add $FILE

git commit --message="Added cypress files."
npx prettier --write .
git add --all
git commit --message "npx prettier --write ."

mkdir -p cypress/e2e && echo "Created cypress/e2e folder" || exit 1

mkdir -p cypress/e2e/pages && echo "Created cypress/e2e/pages folder" || exit 1

mkdir -p cypress/e2e/pages/Learn && echo "Created cypress/e2e/pages/Learn folder" || exit 1

mkdir -p cypress/e2e/pages/Learn/Algorithms && echo "Created cypress/e2e/pages/Learn/Algorithms folder" || exit 1

FILE=cypress/e2e/pages/Learn/Algorithms/Algorithms.cy.ts
cat > $FILE << EOF
describe("Algorithms pages", () => {
  it("passes", () => {
    cy.visit("http://localhost:3000/learn/algorithms");
    cy.url().should("include", "/learn/algorithms");
    cy.get("h1").contains("Algorithms");

    cy.get("#breadcrumbs-link-home").contains("Home").click();
    cy.url().should("include", "/");
    cy.get("h1").contains("intrepion");
    cy.go("back");
    cy.url().should("include", "/learn/algorithms");
    cy.get("h1").contains("Algorithms");

    cy.get("#breadcrumbs-link-learn").contains("Learn").click();
    cy.url().should("include", "/learn");
    cy.get("h1").contains("Let's Learn");
    cy.go("back");
    cy.url().should("include", "/learn/algorithms");
    cy.get("h1").contains("Algorithms");
  });
});
EOF
git add $FILE

mkdir -p cypress/e2e/pages/Learn/BestPractices && echo "Created cypress/e2e/pages/Learn/BestPractices folder" || exit 1

FILE=cypress/e2e/pages/Learn/BestPractices/BestPractices.cy.ts
cat > $FILE << EOF
describe("Best Practices pages", () => {
  it("passes", () => {
    cy.visit("http://localhost:3000/learn/best-practices");
    cy.url().should("include", "/learn/best-practices");
    cy.get("h1").contains("Best Practices");

    cy.get("#breadcrumbs-link-home").contains("Home").click();
    cy.url().should("include", "/");
    cy.get("h1").contains("intrepion");
    cy.go("back");
    cy.url().should("include", "/learn/best-practices");
    cy.get("h1").contains("Best Practices");

    cy.get("#breadcrumbs-link-learn").contains("Learn").click();
    cy.url().should("include", "/learn");
    cy.get("h1").contains("Let's Learn");
    cy.go("back");
    cy.url().should("include", "/learn/best-practices");
    cy.get("h1").contains("Best Practices");
  });
});
EOF
git add $FILE

mkdir -p cypress/e2e/pages/Learn/DataStructures && echo "Created cypress/e2e/pages/Learn/DataStructures folder" || exit 1

FILE=cypress/e2e/pages/Learn/DataStructures/DataStructures.cy.ts
cat > $FILE << EOF
describe("Data Structures pages", () => {
  it("passes", () => {
    cy.visit("http://localhost:3000/learn/data-structures");
    cy.url().should("include", "/learn/data-structures");
    cy.get("h1").contains("Data Structures");

    cy.get("#breadcrumbs-link-home").contains("Home").click();
    cy.url().should("include", "/");
    cy.get("h1").contains("intrepion");
    cy.go("back");
    cy.url().should("include", "/learn/data-structures");
    cy.get("h1").contains("Data Structures");

    cy.get("#breadcrumbs-link-learn").contains("Learn").click();
    cy.url().should("include", "/learn");
    cy.get("h1").contains("Let's Learn");
    cy.go("back");
    cy.url().should("include", "/learn/data-structures");
    cy.get("h1").contains("Data Structures");
  });
});
EOF
git add $FILE

mkdir -p cypress/e2e/pages/Learn/DesignPatterns && echo "Created cypress/e2e/pages/Learn/DesignPatterns folder" || exit 1

mkdir -p cypress/e2e/pages/Learn/DesignPatterns/ArchitecturalPatterns && echo "Created cypress/e2e/pages/Learn/DesignPatterns/ArchitecturalPatterns folder" || exit 1

FILE=cypress/e2e/pages/Learn/DesignPatterns/ArchitecturalPatterns/ArchitecturalPatterns.cy.ts
cat > $FILE << EOF
describe("Architectural Patterns pages", () => {
  it("passes", () => {
    cy.visit(
      "http://localhost:3000/learn/design-patterns/architectural-patterns"
    );
    cy.url().should("include", "/learn/design-patterns/architectural-patterns");
    cy.get("h1").contains("Architectural Patterns");

    cy.get("#breadcrumbs-link-home").contains("Home").click();
    cy.url().should("include", "/");
    cy.get("h1").contains("intrepion");
    cy.go("back");
    cy.url().should("include", "/learn/design-patterns/architectural-patterns");
    cy.get("h1").contains("Architectural Patterns");

    cy.get("#breadcrumbs-link-learn").contains("Learn").click();
    cy.url().should("include", "/learn");
    cy.get("h1").contains("Let's Learn");
    cy.go("back");
    cy.url().should("include", "/learn/design-patterns/architectural-patterns");
    cy.get("h1").contains("Architectural Patterns");

    cy.get("#breadcrumbs-link-design-patterns")
      .contains("Design Patterns")
      .click();
    cy.url().should("include", "/design-patterns");
    cy.get("h1").contains("Design Patterns");
    cy.go("back");
    cy.url().should("include", "/learn/design-patterns/architectural-patterns");
    cy.get("h1").contains("Architectural Patterns");
  });
});
EOF
git add $FILE

mkdir -p cypress/e2e/pages/Learn/DesignPatterns/BehavioralPatterns && echo "Created cypress/e2e/pages/Learn/DesignPatterns/BehavioralPatterns folder" || exit 1

FILE=cypress/e2e/pages/Learn/DesignPatterns/BehavioralPatterns/BehavioralPatterns.cy.ts
cat > $FILE << EOF
describe("Behavioral Patterns pages", () => {
  it("passes", () => {
    cy.visit("http://localhost:3000/learn/design-patterns/behavioral-patterns");
    cy.url().should("include", "/learn/design-patterns/behavioral-patterns");
    cy.get("h1").contains("Behavioral Patterns");

    cy.get("#breadcrumbs-link-home").contains("Home").click();
    cy.url().should("include", "/");
    cy.get("h1").contains("intrepion");
    cy.go("back");
    cy.url().should("include", "/learn/design-patterns/behavioral-patterns");
    cy.get("h1").contains("Behavioral Patterns");

    cy.get("#breadcrumbs-link-learn").contains("Learn").click();
    cy.url().should("include", "/learn");
    cy.get("h1").contains("Let's Learn");
    cy.go("back");
    cy.url().should("include", "/learn/design-patterns/behavioral-patterns");
    cy.get("h1").contains("Behavioral Patterns");

    cy.get("#breadcrumbs-link-design-patterns")
      .contains("Design Patterns")
      .click();
    cy.url().should("include", "/design-patterns");
    cy.get("h1").contains("Design Patterns");
    cy.go("back");
    cy.url().should("include", "/learn/design-patterns/behavioral-patterns");
    cy.get("h1").contains("Behavioral Patterns");
  });
});
EOF
git add $FILE

mkdir -p cypress/e2e/pages/Learn/DesignPatterns/ConcurrencyPatterns && echo "Created cypress/e2e/pages/Learn/DesignPatterns/ConcurrencyPatterns folder" || exit 1

FILE=cypress/e2e/pages/Learn/DesignPatterns/ConcurrencyPatterns/ConcurrencyPatterns.cy.ts
cat > $FILE << EOF
describe("Concurrency Patterns pages", () => {
  it("passes", () => {
    cy.visit(
      "http://localhost:3000/learn/design-patterns/concurrency-patterns"
    );
    cy.url().should("include", "/learn/design-patterns/concurrency-patterns");
    cy.get("h1").contains("Concurrency Patterns");

    cy.get("#breadcrumbs-link-home").contains("Home").click();
    cy.url().should("include", "/");
    cy.get("h1").contains("intrepion");
    cy.go("back");
    cy.url().should("include", "/learn/design-patterns/concurrency-patterns");
    cy.get("h1").contains("Concurrency Patterns");

    cy.get("#breadcrumbs-link-learn").contains("Learn").click();
    cy.url().should("include", "/learn");
    cy.get("h1").contains("Let's Learn");
    cy.go("back");
    cy.url().should("include", "/learn/design-patterns/concurrency-patterns");
    cy.get("h1").contains("Concurrency Patterns");

    cy.get("#breadcrumbs-link-design-patterns")
      .contains("Design Patterns")
      .click();
    cy.url().should("include", "/design-patterns");
    cy.get("h1").contains("Design Patterns");
    cy.go("back");
    cy.url().should("include", "/learn/design-patterns/concurrency-patterns");
    cy.get("h1").contains("Concurrency Patterns");
  });
});
EOF
git add $FILE

mkdir -p cypress/e2e/pages/Learn/DesignPatterns/CreationalPatterns && echo "Created cypress/e2e/pages/Learn/DesignPatterns/CreationalPatterns folder" || exit 1

FILE=cypress/e2e/pages/Learn/DesignPatterns/CreationalPatterns/CreationalPatterns.cy.ts
cat > $FILE << EOF
describe("Creational Patterns pages", () => {
  it("passes", () => {
    cy.visit("http://localhost:3000/learn/design-patterns/creational-patterns");
    cy.url().should("include", "/learn/design-patterns/creational-patterns");
    cy.get("h1").contains("Creational Patterns");

    cy.get("#breadcrumbs-link-home").contains("Home").click();
    cy.url().should("include", "/");
    cy.get("h1").contains("intrepion");
    cy.go("back");
    cy.url().should("include", "/learn/design-patterns/creational-patterns");
    cy.get("h1").contains("Creational Patterns");

    cy.get("#breadcrumbs-link-learn").contains("Learn").click();
    cy.url().should("include", "/learn");
    cy.get("h1").contains("Let's Learn");
    cy.go("back");
    cy.url().should("include", "/learn/design-patterns/creational-patterns");
    cy.get("h1").contains("Creational Patterns");

    cy.get("#breadcrumbs-link-design-patterns")
      .contains("Design Patterns")
      .click();
    cy.url().should("include", "/design-patterns");
    cy.get("h1").contains("Design Patterns");
    cy.go("back");
    cy.url().should("include", "/learn/design-patterns/creational-patterns");
    cy.get("h1").contains("Creational Patterns");
  });
});
EOF
git add $FILE

mkdir -p cypress/e2e/pages/Learn/DesignPatterns/StructuralPatterns && echo "Created cypress/e2e/pages/Learn/DesignPatterns/StructuralPatterns folder" || exit 1

FILE=cypress/e2e/pages/Learn/DesignPatterns/StructuralPatterns/StructuralPatterns.cy.ts
cat > $FILE << EOF
describe("Structural Patterns pages", () => {
  it("passes", () => {
    cy.visit("http://localhost:3000/learn/design-patterns/structural-patterns");
    cy.url().should("include", "/learn/design-patterns/structural-patterns");
    cy.get("h1").contains("Structural Patterns");

    cy.get("#breadcrumbs-link-home").contains("Home").click();
    cy.url().should("include", "/");
    cy.get("h1").contains("intrepion");
    cy.go("back");
    cy.url().should("include", "/learn/design-patterns/structural-patterns");
    cy.get("h1").contains("Structural Patterns");

    cy.get("#breadcrumbs-link-learn").contains("Learn").click();
    cy.url().should("include", "/learn");
    cy.get("h1").contains("Let's Learn");
    cy.go("back");
    cy.url().should("include", "/learn/design-patterns/structural-patterns");
    cy.get("h1").contains("Structural Patterns");

    cy.get("#breadcrumbs-link-design-patterns")
      .contains("Design Patterns")
      .click();
    cy.url().should("include", "/design-patterns");
    cy.get("h1").contains("Design Patterns");
    cy.go("back");
    cy.url().should("include", "/learn/design-patterns/structural-patterns");
    cy.get("h1").contains("Structural Patterns");
  });
});
EOF
git add $FILE

FILE=cypress/e2e/pages/Learn/DesignPatterns/DesignPatterns.cy.ts
cat > $FILE << EOF
describe("Design Patterns pages", () => {
  it("passes", () => {
    cy.visit("http://localhost:3000/learn/design-patterns");
    cy.url().should("include", "/learn/design-patterns");
    cy.get("h1").contains("Design Patterns");

    cy.get("#breadcrumbs-link-home").contains("Home").click();
    cy.url().should("include", "/");
    cy.get("h1").contains("intrepion");
    cy.go("back");
    cy.url().should("include", "/learn/design-patterns");
    cy.get("h1").contains("Design Patterns");

    cy.get("#breadcrumbs-link-learn").contains("Learn").click();
    cy.url().should("include", "/learn");
    cy.get("h1").contains("Let's Learn");
    cy.go("back");
    cy.url().should("include", "/learn/design-patterns");
    cy.get("h1").contains("Design Patterns");

    cy.get("#cards-link-creational-patterns").contains("Learn").click();
    cy.url().should("include", "/learn/design-patterns/creational-patterns");
    cy.get("h1").contains("Creational Patterns");
    cy.go("back");
    cy.url().should("include", "/learn/design-patterns");
    cy.get("h1").contains("Design Patterns");

    cy.get("#cards-link-structural-patterns").contains("Learn").click();
    cy.url().should("include", "/learn/design-patterns/structural-patterns");
    cy.get("h1").contains("Structural Patterns");
    cy.go("back");
    cy.url().should("include", "/learn/design-patterns");
    cy.get("h1").contains("Design Patterns");

    cy.get("#cards-link-behavioral-patterns").contains("Learn").click();
    cy.url().should("include", "/learn/design-patterns/behavioral-patterns");
    cy.get("h1").contains("Behavioral Patterns");
    cy.go("back");
    cy.url().should("include", "/learn/design-patterns");
    cy.get("h1").contains("Design Patterns");

    cy.get("#cards-link-concurrency-patterns").contains("Learn").click();
    cy.url().should("include", "/learn/design-patterns/concurrency-patterns");
    cy.get("h1").contains("Concurrency Patterns");
    cy.go("back");
    cy.url().should("include", "/learn/design-patterns");
    cy.get("h1").contains("Design Patterns");

    cy.get("#cards-link-architectural-patterns").contains("Learn").click();
    cy.url().should("include", "/learn/design-patterns/architectural-patterns");
    cy.get("h1").contains("Architectural Patterns");
    cy.go("back");
    cy.url().should("include", "/learn/design-patterns");
    cy.get("h1").contains("Design Patterns");
  });
});
EOF
git add $FILE

mkdir -p cypress/e2e/pages/Learn/Principles && echo "Created cypress/e2e/pages/Learn/Principles folder" || exit 1

mkdir -p cypress/e2e/pages/Learn/Principles/SolidPrinciples && echo "Created cypress/e2e/pages/Learn/Principles/SolidPrinciples folder" || exit 1

FILE=cypress/e2e/pages/Learn/Principles/SolidPrinciples/SolidPrinciples.cy.ts
cat > $FILE << EOF
describe("SOLID Principles pages", () => {
  it("passes", () => {
    cy.visit("http://localhost:3000/learn/principles/solid-principles");
    cy.url().should("include", "/learn/principles/solid-principles");
    cy.get("h1").contains("SOLID Principles");

    cy.get("#breadcrumbs-link-home").contains("Home").click();
    cy.url().should("include", "/");
    cy.get("h1").contains("intrepion");
    cy.go("back");
    cy.url().should("include", "/learn/principles/solid-principles");
    cy.get("h1").contains("SOLID Principles");

    cy.get("#breadcrumbs-link-learn").contains("Learn").click();
    cy.url().should("include", "/learn");
    cy.get("h1").contains("Let's Learn");
    cy.go("back");
    cy.url().should("include", "/learn/principles/solid-principles");
    cy.get("h1").contains("SOLID Principles");

    cy.get("#breadcrumbs-link-principles").contains("Principles").click();
    cy.url().should("include", "/learn/principles");
    cy.get("h1").contains("Principles");
    cy.go("back");
    cy.url().should("include", "/learn/principles/solid-principles");
    cy.get("h1").contains("SOLID Principles");
  });
});
EOF
git add $FILE

FILE=cypress/e2e/pages/Learn/Principles/Principles.cy.ts
cat > $FILE << EOF
describe("Principles pages", () => {
  it("passes", () => {
    cy.visit("http://localhost:3000/learn/principles");
    cy.url().should("include", "/learn/principles");
    cy.get("h1").contains("Principles");

    cy.get("#breadcrumbs-link-home").contains("Home").click();
    cy.url().should("include", "/");
    cy.get("h1").contains("intrepion");
    cy.go("back");
    cy.url().should("include", "/learn/principles");
    cy.get("h1").contains("Principles");

    cy.get("#breadcrumbs-link-learn").contains("Learn").click();
    cy.url().should("include", "/learn");
    cy.get("h1").contains("Let's Learn");
    cy.go("back");
    cy.url().should("include", "/learn/principles");
    cy.get("h1").contains("Principles");

    cy.get("#cards-link-solid-principles").contains("Learn").click();
    cy.url().should("include", "/learn/principles/solid-principles");
    cy.get("h1").contains("Principles");
    cy.go("back");
    cy.url().should("include", "/learn/principles");
    cy.get("h1").contains("Principles");
  });
});
EOF
git add $FILE

FILE=cypress/e2e/pages/Learn/Learn.cy.ts
cat > $FILE << EOF
describe("Learn pages", () => {
  it("passes", () => {
    cy.visit("http://localhost:3000/learn");
    cy.url().should("include", "/learn");
    cy.get("h1").contains("Let's Learn");

    cy.get("#breadcrumbs-link-home").contains("Home").click();
    cy.url().should("include", "/");
    cy.get("h1").contains("intrepion");
    cy.go("back");
    cy.url().should("include", "/learn");
    cy.get("h1").contains("Let's Learn");

    cy.get("#cards-link-data-structures").contains("Learn").click();
    cy.url().should("include", "/learn/data-structures");
    cy.get("h1").contains("Data Structures");
    cy.go("back");
    cy.url().should("include", "/learn");
    cy.get("h1").contains("Let's Learn");

    cy.get("#cards-link-algorithms").contains("Learn").click();
    cy.url().should("include", "/learn/algorithms");
    cy.get("h1").contains("Algorithms");
    cy.go("back");
    cy.url().should("include", "/learn");
    cy.get("h1").contains("Let's Learn");

    cy.get("#cards-link-design-patterns").contains("Learn").click();
    cy.url().should("include", "/learn/design-patterns");
    cy.get("h1").contains("Design Patterns");
    cy.go("back");
    cy.url().should("include", "/learn");
    cy.get("h1").contains("Let's Learn");

    cy.get("#cards-link-principles").contains("Learn").click();
    cy.url().should("include", "/learn/principles");
    cy.get("h1").contains("Principles");
    cy.go("back");
    cy.url().should("include", "/learn");
    cy.get("h1").contains("Let's Learn");

    cy.get("#cards-link-best-practices").contains("Learn").click();
    cy.url().should("include", "/learn/best-practices");
    cy.get("h1").contains("Best Practices");
    cy.go("back");
    cy.url().should("include", "/learn");
    cy.get("h1").contains("Let's Learn");
  });
});
EOF
git add $FILE

FILE=cypress/e2e/pages/index.cy.ts
cat > $FILE << EOF
describe("index pages", () => {
  it("passes", () => {
    cy.visit("http://localhost:3000");
    cy.url().should("include", "/");
    cy.get("h1").contains("intrepion");

    cy.get("#navigations-link-intrepion").contains("intrepion").click();
    cy.url().should("include", "/");
    cy.get("h1").contains("intrepion");

    cy.get("#navigations-link-home").contains("Home").click();
    cy.url().should("include", "/");
    cy.get("h1").contains("intrepion");

    cy.get("#navigations-link-learn").contains("Learn").click();
    cy.url().should("include", "/learn");
    cy.get("h1").contains("Let's Learn");
    cy.go("back");
    cy.url().should("include", "/");
    cy.get("h1").contains("intrepion");

    cy.get("#navigations-link-about").contains("About").click();
    cy.url().should("include", "/about");
    cy.get("h1").contains("OLIVER FORRAL");
    cy.go("back");
    cy.url().should("include", "/");
    cy.get("h1").contains("intrepion");

    cy.get("#navigations-link-log-in").contains("Log In").click();
    cy.url().should("include", "/authentication/log-in");
    cy.get("h1").contains("Log In");
    cy.go("back");
    cy.url().should("include", "/");
    cy.get("h1").contains("intrepion");

    cy.get("#navigations-link-register").contains("Register").click();
    cy.url().should("include", "/authentication/register");
    cy.get("h1").contains("Register");
    cy.go("back");
    cy.url().should("include", "/");
    cy.get("h1").contains("intrepion");

    cy.get("#cards-link-learn").contains("Learn").click();
    cy.url().should("include", "/learn");
    cy.get("h1").contains("Let's Learn");
    cy.go("back");
    cy.url().should("include", "/");
    cy.get("h1").contains("intrepion");

    cy.get("#socials-link-twitter").should((\$a) => {
      expect(\$a.attr("href"), "href").contains("twitter.com");
      expect(\$a.attr("rel"), "rel").to.equal("noopener noreferrer");
      expect(\$a.attr("target"), "target").to.equal("_blank");
    });
  });
});
EOF
git add $FILE

FILE=cypress/e2e/users.cy.ts
cat > $FILE << EOF
/// <reference types="cypress" />

describe("users", () => {
  it("passes", () => {
    cy.intercept("POST", /^http.*\/Users$/, {
      fixture: "register-new-user.json",
    }).as("register");
    cy.visit("http://localhost:3000");
    cy.get("#navigations-link-register").contains("Register").click();
  });
});

EOF
git add $FILE

npx cypress run && exit 1 || git commit --message="red - test pages"
npx prettier --write .
git add --all
git commit --message "npx prettier --write ."

FILE=public/index.html
cat > $FILE << EOF
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <link rel="icon" href="%PUBLIC_URL%/favicon.ico" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta name="theme-color" content="#000000" />
    <meta name="description" content="$CANONICAL" />
    <link rel="apple-touch-icon" href="%PUBLIC_URL%/logo192.png" />
    <link rel="manifest" href="%PUBLIC_URL%/manifest.json" />
    <link
      href="https://fonts.googleapis.com/css?family=Saira+Extra+Condensed:500,700"
      rel="stylesheet"
      type="text/css"
    />
    <link
      href="https://fonts.googleapis.com/css?family=Muli:400,400i,800,800i"
      rel="stylesheet"
      type="text/css"
    />
    <link
      href="https://cdnjs.cloudflare.com/ajax/libs/bootstrap/5.2.3/css/bootstrap.min.css"
      rel="stylesheet"
    />
    <link
      href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.2.1/css/all.min.css"
      rel="stylesheet"
    />
    <title>$CANONICAL</title>
  </head>
  <body>
    <noscript>You need to enable JavaScript to run this app.</noscript>
    <div id="root"></div>
  </body>
</html>
EOF
git add $FILE

mkdir -p src/pages && echo "Created src/pages folder" || exit 1

mkdir -p src/pages/Authentication && echo "Created src/pages/Authentication folder" || exit 1

FILE=src/pages/Authentication/LogIn.tsx
cat > $FILE << EOF
import axios from "axios";
import { ChangeEvent, useContext, useState } from "react";
import { Button, Col, Form, InputGroup, Row } from "react-bootstrap";
import { Navigate } from "react-router-dom";
import { AuthContext } from "../../AuthProvider";

const LogIn = () => {
  const { authenticatedUserName, serverUrl, setAuthenticatedUserName } =
    useContext(AuthContext);
  const [isHandlingLogIn, setIsHandlingLogIn] = useState(false);
  const [password, setPassword] = useState("");
  const [rememberMe, setRememberMe] = useState(false);
  const [userName, setUserName] = useState("");
  const [validated, setValidated] = useState(false);

  const handleChangePassword = (event: ChangeEvent<HTMLInputElement>) => {
    setPassword(event.target.value);
  };

  const handleChangeRememberMe = (event: ChangeEvent<HTMLInputElement>) => {
    setRememberMe(event.target.checked);
  };

  const handleChangeUserName = (event: ChangeEvent<HTMLInputElement>) => {
    setUserName(event.target.value);
  };

  const handleLogIn = async (event: {
    currentTarget: any;
    preventDefault: () => void;
    stopPropagation: () => void;
  }) => {
    event.preventDefault();
    event.stopPropagation();
    const form = event.currentTarget;
    const valid = form.checkValidity();
    setValidated(true);
    if (valid === false) {
      return;
    }
    setIsHandlingLogIn(true);
    const values = {
      password,
      rememberMe,
      userName,
    };
    try {
      const response = await axios.post(serverUrl + "/LogIns", values);
      if (response.data) {
        const { userName } = response.data;
        setAuthenticatedUserName(userName);
      }
    } catch (error) {
      console.log(error);
    }
    setIsHandlingLogIn(false);
  };

  return (
    <>
      <div className="p-5 mb-4 bg-light rounded-3">
        <div className="container-fluid py-5">
          <h1 className="display-5 fw-bold">Log In</h1>
          <p className="col-md-8 fs-4">Please log in.</p>
        </div>
      </div>
      <div>
        <Form noValidate validated={validated} onSubmit={handleLogIn}>
          <Row className="mb-3">
            <Form.Group as={Col} md="4" controlId="validationCustomUserName">
              <Form.Label>User Name</Form.Label>
              <InputGroup hasValidation>
                <InputGroup.Text id="inputGroupPrependUserName">
                  @
                </InputGroup.Text>
                <Form.Control
                  aria-describedby="inputGroupPrependUserName"
                  onChange={handleChangeUserName}
                  placeholder="User Name"
                  required
                  type="text"
                  value={userName}
                />
                <Form.Control.Feedback type="invalid">
                  Please provide a valid user name.
                </Form.Control.Feedback>
              </InputGroup>
            </Form.Group>
          </Row>
          <Row className="mb-3">
            <Form.Group as={Col} md="4" controlId="validationCustomPassword">
              <Form.Label>Password</Form.Label>
              <Form.Control
                onChange={handleChangePassword}
                placeholder="Password"
                required
                type="password"
                value={password}
              />
              <Form.Control.Feedback type="invalid">
                Please provide a valid password.
              </Form.Control.Feedback>
            </Form.Group>
          </Row>
          <Form.Group className="mb-3">
            <Form.Check
              checked={rememberMe}
              label="Remember Me"
              onChange={handleChangeRememberMe}
            />
          </Form.Group>
          <Button disabled={isHandlingLogIn} type="submit">
            Login
          </Button>
        </Form>
      </div>
      {authenticatedUserName && <Navigate to="/" replace={true} />}
    </>
  );
};

export default LogIn;
EOF
git add $FILE

FILE=src/pages/Authentication/LogOut.tsx
cat > $FILE << EOF
import axios from "axios";
import { useContext, useEffect, useState } from "react";
import { Navigate } from "react-router-dom";
import { AuthContext } from "../../AuthProvider";

const LogOut = () => {
  const { authenticatedUserName, serverUrl, setAuthenticatedUserName } =
    useContext(AuthContext);
  const [isHandlingLogOut, setIsHandlingLogOut] = useState(false);
  const [successLogOut, setSuccessLogOut] = useState(false);

  const handleLogOut = async () => {
    setIsHandlingLogOut(true);
    try {
      const response = await axios.post(serverUrl + "/LogOuts");
      if (response.data) {
        setAuthenticatedUserName("");
        setSuccessLogOut(true);
      } else {
        setSuccessLogOut(false);
      }
    } catch (error) {
      console.log(error);
      setSuccessLogOut(false);
    }
    setIsHandlingLogOut(false);
  };

  useEffect(() => {
    handleLogOut();
  });

  return (
    <>
      {!isHandlingLogOut && successLogOut && !authenticatedUserName && (
        <Navigate to="/log-in" replace={true} />
      )}
    </>
  );
};

export default LogOut;
EOF
git add $FILE

FILE=src/pages/Authentication/Register.tsx
cat > $FILE << EOF
import axios from "axios";
import { ChangeEvent, useContext, useState } from "react";
import { Button, Col, Form, InputGroup, Row } from "react-bootstrap";
import { Navigate } from "react-router-dom";
import { AuthContext } from "../../AuthProvider";

const Register = () => {
  const [accept, setAccept] = useState(false);
  const [confirm, setConfirm] = useState("");
  const [email, setEmail] = useState("");
  const [isHandlingRegister, setIsHandlingRegister] = useState(false);
  const [password, setPassword] = useState("");
  const { serverUrl } = useContext(AuthContext);
  const [successRegister, setSuccessRegister] = useState(false);
  const [userName, setUserName] = useState("");
  const [validated, setValidated] = useState(false);

  const handleChangeAccept = (event: ChangeEvent<HTMLInputElement>) => {
    setAccept(event.target.checked);
  };

  const handleChangeConfirm = (event: ChangeEvent<HTMLInputElement>) => {
    setConfirm(event.target.value);
  };

  const handleChangeEmail = (event: ChangeEvent<HTMLInputElement>) => {
    setEmail(event.target.value);
  };

  const handleChangePassword = (event: ChangeEvent<HTMLInputElement>) => {
    setPassword(event.target.value);
  };

  const handleChangeUserName = (event: ChangeEvent<HTMLInputElement>) => {
    setUserName(event.target.value);
  };

  const handleRegister = async (event: {
    currentTarget: any;
    preventDefault: () => void;
    stopPropagation: () => void;
  }) => {
    event.preventDefault();
    event.stopPropagation();
    const form = event.currentTarget;
    const valid = form.checkValidity();
    setValidated(true);
    if (valid === false) {
      return;
    }
    setIsHandlingRegister(true);
    const values = {
      accept,
      confirm,
      email,
      password,
      userName,
    };
    try {
      const response = await axios.post(serverUrl + "/Users", values);
      if (response.data) {
        setSuccessRegister(true);
      } else {
        setSuccessRegister(false);
      }
    } catch (error) {
      console.log(error);
      setSuccessRegister(false);
    }
    setIsHandlingRegister(false);
  };

  return (
    <>
      <div className="p-5 mb-4 bg-light rounded-3">
        <div className="container-fluid py-5">
          <h1 className="display-5 fw-bold">Register</h1>
          <p className="col-md-8 fs-4">Please register.</p>
        </div>
      </div>
      <div>
        <Form noValidate validated={validated} onSubmit={handleRegister}>
          <Row className="mb-3">
            <Form.Group as={Col} md="4" controlId="validationCustomUserName">
              <Form.Label>User Name</Form.Label>
              <InputGroup hasValidation>
                <InputGroup.Text id="inputGroupPrependUserName">
                  @
                </InputGroup.Text>
                <Form.Control
                  aria-describedby="inputGroupPrependUserName"
                  onChange={handleChangeUserName}
                  placeholder="User Name"
                  required
                  type="text"
                  value={userName}
                />
                <Form.Control.Feedback type="invalid">
                  Please provide a valid user name.
                </Form.Control.Feedback>
              </InputGroup>
            </Form.Group>
          </Row>
          <Row className="mb-3">
            <Form.Group as={Col} md="4" controlId="validationCustomEmail">
              <Form.Label>Email</Form.Label>
              <InputGroup hasValidation>
                <InputGroup.Text id="inputGroupPrependEmail">
                  mailto:
                </InputGroup.Text>
                <Form.Control
                  aria-describedby="inputGroupPrependEmail"
                  onChange={handleChangeEmail}
                  placeholder="Email"
                  required
                  type="email"
                  value={email}
                />
                <Form.Control.Feedback type="invalid">
                  Please provide a valid user name.
                </Form.Control.Feedback>
              </InputGroup>
            </Form.Group>
          </Row>
          <Row className="mb-3">
            <Form.Group as={Col} md="4" controlId="validationCustomPassword">
              <Form.Label>Password</Form.Label>
              <Form.Control
                onChange={handleChangePassword}
                placeholder="Password"
                required
                type="password"
                value={password}
              />
              <Form.Control.Feedback type="invalid">
                Please provide a valid password.
              </Form.Control.Feedback>
            </Form.Group>
          </Row>
          <Row className="mb-3">
            <Form.Group as={Col} md="4" controlId="validationCustomConfirm">
              <Form.Label>Confirm</Form.Label>
              <Form.Control
                onChange={handleChangeConfirm}
                placeholder="Confirm"
                required
                type="password"
                value={confirm}
              />
              <Form.Control.Feedback type="invalid">
                Please provide a valid confirm.
              </Form.Control.Feedback>
            </Form.Group>
          </Row>
          <Form.Group className="mb-3">
            <Form.Check
              checked={accept}
              label="Accept terms of service"
              onChange={handleChangeAccept}
              required
            />
            <Form.Control.Feedback type="invalid">
              Please accept the terms of service.
            </Form.Control.Feedback>
          </Form.Group>
          <Button disabled={isHandlingRegister} type="submit">
            Login
          </Button>
        </Form>
      </div>
      {successRegister && <Navigate to="/log-in" replace={true} />}
    </>
  );
};

export default Register;
EOF
git add $FILE

mkdir -p src/pages/Learn && echo "Created src/pages/Learn folder" || exit 1

mkdir -p src/pages/Learn/Algorithms && echo "Created src/pages/Learn/Algorithms folder" || exit 1

FILE=src/pages/Learn/Algorithms/Algorithms.tsx
cat > $FILE << EOF
import { Breadcrumb } from "react-bootstrap";
import { Link } from "react-router-dom";

const Algorithms = () => {
  return (
    <>
      <div className="p-5 mb-4 bg-light rounded-3">
        <div className="container-fluid py-5">
          <h1 className="display-5 fw-bold">Algorithms</h1>
          <p className="col-md-8 fs-4">
            An algorithm is a set of steps to solve a specific problem. In
            computer science, algorithms are used to process data, sort and
            search information, and make decisions.
          </p>
        </div>
      </div>
      <div className="container px-4 py-2">
        <div className="row">
          <div className="col-12">
            <Breadcrumb>
              <Breadcrumb.Item
                id="breadcrumbs-link-home"
                linkAs={Link}
                linkProps={{ to: "/" }}
              >
                Home
              </Breadcrumb.Item>
              <Breadcrumb.Item
                id="breadcrumbs-link-learn"
                linkAs={Link}
                linkProps={{ to: "/learn" }}
              >
                Learn
              </Breadcrumb.Item>
              <Breadcrumb.Item active>Algorithms</Breadcrumb.Item>
            </Breadcrumb>
          </div>
        </div>
      </div>
      <div className="container px-4 py-2">
        <div className="row">
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Sorting Algorithms</h2>
              <p>
                Sorting Algorithms are used to arrange data in a specific order,
                such as bubble sort, insertion sort, and merge sort.
              </p>
            </div>
          </div>
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Search Algorithms</h2>
              <p>
                Search Algorithms are used to find an item in a dataset, such as
                linear search and binary search.
              </p>
            </div>
          </div>
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Graph Algorithms</h2>
              <p>
                Graph Algorithms are used to process and analyze graph data
                structures, such as breadth-first search and Dijkstra's shortest
                path.
              </p>
            </div>
          </div>
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Dynamic Programming Algorithms</h2>
              <p>
                Dynamic Programming Algorithms are used to solve problems by
                breaking them down into smaller subproblems, such as the
                Fibonacci sequence and the knapsack problem.
              </p>
            </div>
          </div>
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Divide and Conquer Algorithms</h2>
              <p>
                Divide and Conquer Algorithms are used to solve problems by
                dividing the problem into smaller subproblems and solving each
                subproblem, such as quick sort and merge sort.
              </p>
            </div>
          </div>
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Greedy Algorithms</h2>
              <p>
                Greedy Algorithms are used to make locally optimal choices at
                each stage with the hope of finding a global optimum, such as
                the activity selection problem and Kruskal's minimum spanning
                tree.
              </p>
            </div>
          </div>
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Backtracking Algorithms</h2>
              <p>
                Backtracking Algorithms are used to find all possible solutions
                by incrementally building and testing candidate solutions, such
                as the n-queens problem and the traveling salesman problem.{" "}
              </p>
            </div>
          </div>
        </div>
      </div>
    </>
  );
};

export default Algorithms;
EOF
git add $FILE

mkdir -p src/pages/Learn/BestPractices && echo "Created src/pages/Learn/BestPractices folder" || exit 1

FILE=src/pages/Learn/BestPractices/BestPractices.tsx
cat > $FILE << EOF
import { Breadcrumb } from "react-bootstrap";
import { Link } from "react-router-dom";

const BestPractices = () => {
  return (
    <>
      <div className="p-5 mb-4 bg-light rounded-3">
        <div className="container-fluid py-5">
          <h1 className="display-5 fw-bold">Best Practices</h1>
          <p className="col-md-8 fs-4">
            Learn about best practices like Test-Driven Development.
          </p>
        </div>
      </div>
      <div className="container px-4 py-2">
        <div className="row">
          <div className="col-12">
            <Breadcrumb>
              <Breadcrumb.Item
                id="breadcrumbs-link-home"
                linkAs={Link}
                linkProps={{ to: "/" }}
              >
                Home
              </Breadcrumb.Item>
              <Breadcrumb.Item
                id="breadcrumbs-link-learn"
                linkAs={Link}
                linkProps={{ to: "/learn" }}
              >
                Learn
              </Breadcrumb.Item>
              <Breadcrumb.Item active>Best Practices</Breadcrumb.Item>
            </Breadcrumb>
          </div>
        </div>
      </div>
      <div className="container px-4 py-2">
        <div className="row">
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Test-Driven Development</h2>
              <p>
                A software development process relying on software requirements
                being converted to test cases before software is fully
                developed, and tracking all software development by repeatedly
                testing the software against all test cases.
              </p>
            </div>
          </div>
        </div>
      </div>
    </>
  );
};

export default BestPractices;
EOF
git add $FILE

mkdir -p src/pages/Learn/DataStructures && echo "Created src/pages/Learn/DataStructures folder" || exit 1

FILE=src/pages/Learn/DataStructures/DataStructures.tsx
cat > $FILE << EOF
import { Breadcrumb } from "react-bootstrap";
import { Link } from "react-router-dom";

const DataStructures = () => {
  return (
    <>
      <div className="p-5 mb-4 bg-light rounded-3">
        <div className="container-fluid py-5">
          <h1 className="display-5 fw-bold">Data Structures</h1>
          <p className="col-md-8 fs-4">
            Data structures are structures used to organize and store data in a
            computer so that it can be accessed and used efficiently.
          </p>
        </div>
      </div>
      <div className="container px-4 py-2">
        <div className="row">
          <div className="col-12">
            <Breadcrumb>
              <Breadcrumb.Item
                id="breadcrumbs-link-home"
                linkAs={Link}
                linkProps={{ to: "/" }}
              >
                Home
              </Breadcrumb.Item>
              <Breadcrumb.Item
                id="breadcrumbs-link-learn"
                linkAs={Link}
                linkProps={{ to: "/learn" }}
              >
                Learn
              </Breadcrumb.Item>
              <Breadcrumb.Item active>Data Structures</Breadcrumb.Item>
            </Breadcrumb>
          </div>
        </div>
      </div>
      <div className="container px-4 py-2">
        <div className="row">
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Arrays</h2>
              <p>Collection of items stored at contiguous memory locations.</p>
            </div>
          </div>
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Linked List</h2>
              <p>
                Collection of items where each item holds a reference to the
                next item.
              </p>
            </div>
          </div>
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Stack</h2>
              <p>Collection of items with last-in-first-out (LIFO) order.</p>
            </div>
          </div>
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Queue</h2>
              <p>Collection of items with first-in-first-out (FIFO) order.</p>
            </div>
          </div>
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Tree</h2>
              <p>Collection of items organized in a hierarchical structure.</p>
            </div>
          </div>
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Graph</h2>
              <p>
                Collection of items represented as nodes connected by edges.
              </p>
            </div>
          </div>
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Hash Table</h2>
              <p>
                Data structure that implements an associative array, a structure
                that can map keys to values.
              </p>
            </div>
          </div>
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Heap</h2>
              <p>
                Complete binary tree where items are stored in a special order
                such that the parent node is always larger/smaller than its
                child nodes.
              </p>
            </div>
          </div>
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Trie</h2>
              <p>
                Tree-like data structure used for efficient retrieval of data in
                which keys are sequences.
              </p>
            </div>
          </div>
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Matrix</h2>
              <p>2D array used to represent and manipulate numerical data.</p>
            </div>
          </div>
        </div>
      </div>
    </>
  );
};

export default DataStructures;
EOF
git add $FILE

mkdir -p src/pages/Learn/DesignPatterns && echo "Created src/pages/Learn/DesignPatterns folder" || exit 1

mkdir -p src/pages/Learn/DesignPatterns/ArchitecturalPatterns && echo "Created src/pages/Learn/DesignPatterns/ArchitecturalPatterns folder" || exit 1

FILE=src/pages/Learn/DesignPatterns/ArchitecturalPatterns/ArchitecturalPatterns.tsx
cat > $FILE << EOF
import { Breadcrumb } from "react-bootstrap";
import { Link } from "react-router-dom";

const ArchitecturalPatterns = () => {
  return (
    <>
      <div className="p-5 mb-4 bg-light rounded-3">
        <div className="container-fluid py-5">
          <h1 className="display-5 fw-bold">Architectural Patterns</h1>
          <p className="col-md-8 fs-4">
            These patterns are focused on overall software architecture, and
            high-level structural organization of code.
          </p>
        </div>
      </div>
      <div className="container px-4 py-2">
        <div className="row">
          <div className="col-12">
            <Breadcrumb>
              <Breadcrumb.Item
                id="breadcrumbs-link-home"
                linkAs={Link}
                linkProps={{ to: "/" }}
              >
                Home
              </Breadcrumb.Item>
              <Breadcrumb.Item
                id="breadcrumbs-link-learn"
                linkAs={Link}
                linkProps={{ to: "/learn" }}
              >
                Learn
              </Breadcrumb.Item>
              <Breadcrumb.Item
                id="breadcrumbs-link-design-patterns"
                linkAs={Link}
                linkProps={{ to: "/learn/design-patterns" }}
              >
                Design Patterns
              </Breadcrumb.Item>
              <Breadcrumb.Item active>Architectural Patterns</Breadcrumb.Item>
            </Breadcrumb>
          </div>
        </div>
      </div>
      <div className="container px-4 py-2">
        <div className="row">
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Model-View-Controller (MVC)</h2>
              <p>
                This pattern separates the representation of information from
                the user's interaction with it
              </p>
            </div>
          </div>
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Model-View-ViewModel (MVVM)</h2>
              <p>
                This pattern is similar to MVC, but it specifically targets
                UI-based applications and it is used to separate the business
                and presentation logic of an application from its user
                interface.
              </p>
            </div>
          </div>
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Client-Server</h2>
              <p>
                This pattern separates the user interface concerns from the data
                storage concerns, by using a client to interact with a remote
                server.
              </p>
            </div>
          </div>
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Microservices</h2>
              <p>
                This pattern structures an application as a collection of small,
                loosely coupled services, each of which can be developed,
                deployed, and scaled independently.
              </p>
            </div>
          </div>
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Event-Driven</h2>
              <p>
                This pattern allows different parts of an application to
                communicate asynchronously, by sending and receiving events.
              </p>
            </div>
          </div>
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Layered</h2>
              <p>
                This pattern organizes an application into layers, each of which
                has a specific responsibility, such as presentation, business
                logic, and data access.
              </p>
            </div>
          </div>
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Space-Based</h2>
              <p>
                This pattern organizes the components of an application around a
                shared space, such as a database, message queue, or shared
                memory.
              </p>
            </div>
          </div>
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Hexagonal</h2>
              <p>
                This pattern allows an application to be built around the
                business logic, independent of the user interface and
                infrastructure concerns.
              </p>
            </div>
          </div>
        </div>
      </div>
    </>
  );
};

export default ArchitecturalPatterns;
EOF
git add $FILE

mkdir -p src/pages/Learn/DesignPatterns/BehavioralPatterns && echo "Created src/pages/Learn/DesignPatterns/BehavioralPatterns folder" || exit 1

FILE=src/pages/Learn/DesignPatterns/BehavioralPatterns/BehavioralPatterns.tsx
cat > $FILE << EOF
import { Breadcrumb } from "react-bootstrap";
import { Link } from "react-router-dom";

const BehavioralPatterns = () => {
  return (
    <>
      <div className="p-5 mb-4 bg-light rounded-3">
        <div className="container-fluid py-5">
          <h1 className="display-5 fw-bold">Behavioral Patterns</h1>
          <p className="col-md-8 fs-4">
            These patterns are focused on communication between objects, what
            goes on between objects and how they operate together.
          </p>
        </div>
      </div>
      <div className="container px-4 py-2">
        <div className="row">
          <div className="col-12">
            <Breadcrumb>
              <Breadcrumb.Item
                id="breadcrumbs-link-home"
                linkAs={Link}
                linkProps={{ to: "/" }}
              >
                Home
              </Breadcrumb.Item>
              <Breadcrumb.Item
                id="breadcrumbs-link-learn"
                linkAs={Link}
                linkProps={{ to: "/learn" }}
              >
                Learn
              </Breadcrumb.Item>
              <Breadcrumb.Item
                id="breadcrumbs-link-design-patterns"
                linkAs={Link}
                linkProps={{ to: "/learn/design-patterns" }}
              >
                Design Patterns
              </Breadcrumb.Item>
              <Breadcrumb.Item active>Behavioral Patterns</Breadcrumb.Item>
            </Breadcrumb>
          </div>
        </div>
      </div>
      <div className="container px-4 py-2">
        <div className="row">
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Chain of Responsibility</h2>
              <p>
                This pattern allows multiple objects to handle a request, by
                linking them together in a chain.
              </p>
            </div>
          </div>
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Command</h2>
              <p>
                This pattern encapsulates a request as an object, separating the
                command execution from the command initiator.
              </p>
            </div>
          </div>
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Interpreter</h2>
              <p>
                This pattern defines a language and provides an interpreter for
                it.
              </p>
            </div>
          </div>
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Iterator</h2>
              <p>
                This pattern allows sequentially accessing the elements of a
                collection, without exposing its underlying representation.
              </p>
            </div>
          </div>
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Mediator</h2>
              <p>
                This pattern allows objects to communicate without knowing each
                other's identities, by providing a mediator object to handle
                communication between them.
              </p>
            </div>
          </div>
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Memento</h2>
              <p>
                This pattern allows an object to capture its internal state and
                store it, so that it can be restored to that state later.
              </p>
            </div>
          </div>
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Observer</h2>
              <p>
                This pattern allows objects to be notified of changes to other
                objects, without being tightly coupled to them.
              </p>
            </div>
          </div>
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>State</h2>
              <p>
                This pattern allows an object to alter its behavior when its
                internal state changes.
              </p>
            </div>
          </div>
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Strategy</h2>
              <p>
                This pattern allows an object to change its behavior, by
                changing the strategy or algorithm it uses.
              </p>
            </div>
          </div>
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Template Method</h2>
              <p>
                This pattern defines the skeleton of an algorithm, allowing
                subclasses to fill in the details.
              </p>
            </div>
          </div>
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Visitor</h2>
              <p>
                This pattern separates an algorithm from an object structure, by
                moving the algorithm into a separate class called a visitor.
              </p>
            </div>
          </div>
        </div>
      </div>
    </>
  );
};

export default BehavioralPatterns;
EOF
git add $FILE

mkdir -p src/pages/Learn/DesignPatterns/ConcurrencyPatterns && echo "Created src/pages/Learn/DesignPatterns/ConcurrencyPatterns folder" || exit 1

FILE=src/pages/Learn/DesignPatterns/ConcurrencyPatterns/ConcurrencyPatterns.tsx
cat > $FILE << EOF
import { Breadcrumb } from "react-bootstrap";
import { Link } from "react-router-dom";

const ConcurrencyPatterns = () => {
  return (
    <>
      <div className="p-5 mb-4 bg-light rounded-3">
        <div className="container-fluid py-5">
          <h1 className="display-5 fw-bold">Concurrency Patterns</h1>
          <p className="col-md-8 fs-4">
            These patterns are focused on managing concurrent access to shared
            resources and addressing issues that arise in concurrent computing.
          </p>
        </div>
      </div>
      <div className="container px-4 py-2">
        <div className="row">
          <div className="col-12">
            <Breadcrumb>
              <Breadcrumb.Item
                id="breadcrumbs-link-home"
                linkAs={Link}
                linkProps={{ to: "/" }}
              >
                Home
              </Breadcrumb.Item>
              <Breadcrumb.Item
                id="breadcrumbs-link-learn"
                linkAs={Link}
                linkProps={{ to: "/learn" }}
              >
                Learn
              </Breadcrumb.Item>
              <Breadcrumb.Item
                id="breadcrumbs-link-design-patterns"
                linkAs={Link}
                linkProps={{ to: "/learn/design-patterns" }}
              >
                Design Patterns
              </Breadcrumb.Item>
              <Breadcrumb.Item active>Concurrency Patterns</Breadcrumb.Item>
            </Breadcrumb>
          </div>
        </div>
      </div>
      <div className="container px-4 py-2">
        <div className="row">
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Active Object</h2>
              <p>
                This pattern decouples method execution from method invocation,
                allowing for the methods to be executed asynchronously.
              </p>
            </div>
          </div>
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Double-Checked Locking</h2>
              <p>
                This pattern improves the performance of lazy initialization, by
                checking the lock only once, before entering the critical
                section.
              </p>
            </div>
          </div>
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Monitor Object</h2>
              <p>
                This pattern uses an object to synchronize access to a shared
                resource, by using its methods as the critical section.
              </p>
            </div>
          </div>
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Producer-Consumer</h2>
              <p>
                This pattern divides an object into two, the producer that
                creates the data, and the consumer that acts on the data.
              </p>
            </div>
          </div>
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Thread-Pool</h2>
              <p>
                This pattern reuses a fixed number of threads to execute
                multiple tasks, rather than creating a new thread for each task.
              </p>
            </div>
          </div>
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Read-Write Lock</h2>
              <p>
                This pattern allows multiple readers to access a shared resource
                simultaneously, but only one writer at a time.
              </p>
            </div>
          </div>
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Barrier</h2>
              <p>
                This pattern is used to synchronize the execution of multiple
                threads, so that they can wait for each other to reach a
                specific point.
              </p>
            </div>
          </div>
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Future</h2>
              <p>
                This pattern allows an asynchronous computation to be executed
                and the result to be retrieved later.
              </p>
            </div>
          </div>
        </div>
      </div>
    </>
  );
};

export default ConcurrencyPatterns;
EOF
git add $FILE

mkdir -p src/pages/Learn/DesignPatterns/CreationalPatterns && echo "Created src/pages/Learn/DesignPatterns/CreationalPatterns folder" || exit 1

FILE=src/pages/Learn/DesignPatterns/CreationalPatterns/CreationalPatterns.tsx
cat > $FILE << EOF
import { Breadcrumb } from "react-bootstrap";
import { Link } from "react-router-dom";

const CreationalPatterns = () => {
  return (
    <>
      <div className="p-5 mb-4 bg-light rounded-3">
        <div className="container-fluid py-5">
          <h1 className="display-5 fw-bold">Creational Patterns</h1>
          <p className="col-md-8 fs-4">
            These patterns are focused on object creation mechanisms, trying to
            create objects in a manner suitable to the situation.
          </p>
        </div>
      </div>
      <div className="container px-4 py-2">
        <div className="row">
          <div className="col-12">
            <Breadcrumb>
              <Breadcrumb.Item
                id="breadcrumbs-link-home"
                linkAs={Link}
                linkProps={{ to: "/" }}
              >
                Home
              </Breadcrumb.Item>
              <Breadcrumb.Item
                id="breadcrumbs-link-learn"
                linkAs={Link}
                linkProps={{ to: "/learn" }}
              >
                Learn
              </Breadcrumb.Item>
              <Breadcrumb.Item
                id="breadcrumbs-link-design-patterns"
                linkAs={Link}
                linkProps={{ to: "/learn/design-patterns" }}
              >
                Design Patterns
              </Breadcrumb.Item>
              <Breadcrumb.Item active>Creational Patterns</Breadcrumb.Item>
            </Breadcrumb>
          </div>
        </div>
      </div>
      <div className="container px-4 py-2">
        <div className="row">
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Factory Method</h2>
              <p>
                This pattern defines an interface for creating an object, but
                allows subclasses to alter the type of objects that will be
                created.
              </p>
            </div>
          </div>
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Abstract Factory</h2>
              <p>
                This pattern provides an interface for creating families of
                related or dependent objects without specifying their concrete
                classes.
              </p>
            </div>
          </div>
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Builder</h2>
              <p>
                This pattern separates the construction of a complex object from
                its representation, allowing the same construction process to
                create various representations.
              </p>
            </div>
          </div>
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Prototype</h2>
              <p>
                This pattern specifies the kind of objects to create using a
                prototypical instance, and creates new objects by copying this
                prototype.
              </p>
            </div>
          </div>
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Singleton</h2>
              <p>
                This pattern ensures that a class has only one instance, while
                providing a global access point to this instance.
              </p>
            </div>
          </div>
        </div>
      </div>
    </>
  );
};

export default CreationalPatterns;
EOF
git add $FILE

mkdir -p src/pages/Learn/DesignPatterns/StructuralPatterns && echo "Created src/pages/Learn/DesignPatterns/StructuralPatterns folder" || exit 1

FILE=src/pages/Learn/DesignPatterns/StructuralPatterns/StructuralPatterns.tsx
cat > $FILE << EOF
import { Breadcrumb } from "react-bootstrap";
import { Link } from "react-router-dom";

const StructuralPatterns = () => {
  return (
    <>
      <div className="p-5 mb-4 bg-light rounded-3">
        <div className="container-fluid py-5">
          <h1 className="display-5 fw-bold">Structural Patterns</h1>
          <p className="col-md-8 fs-4">
            These patterns deal with object composition, creating relationships
            between objects to form larger structures.
          </p>
        </div>
      </div>
      <div className="container px-4 py-2">
        <div className="row">
          <div className="col-12">
            <Breadcrumb>
              <Breadcrumb.Item
                id="breadcrumbs-link-home"
                linkAs={Link}
                linkProps={{ to: "/" }}
              >
                Home
              </Breadcrumb.Item>
              <Breadcrumb.Item
                id="breadcrumbs-link-learn"
                linkAs={Link}
                linkProps={{ to: "/learn" }}
              >
                Learn
              </Breadcrumb.Item>
              <Breadcrumb.Item
                id="breadcrumbs-link-design-patterns"
                linkAs={Link}
                linkProps={{ to: "/learn/design-patterns" }}
              >
                Design Patterns
              </Breadcrumb.Item>
              <Breadcrumb.Item active>Structural Patterns</Breadcrumb.Item>
            </Breadcrumb>
          </div>
        </div>
      </div>
      <div className="container px-4 py-2">
        <div className="row">
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Adapter</h2>
              <p>
                This pattern allows classes with incompatible interfaces to work
                together by wrapping its own interface around that of an already
                existing class.
              </p>
            </div>
          </div>
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Bridge</h2>
              <p>
                This pattern separates an object's interface from its
                implementation, allowing the two to vary independently.
              </p>
            </div>
          </div>
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Composite</h2>
              <p>
                This pattern allows you to compose objects into tree structures
                to represent part-whole hierarchies.
              </p>
            </div>
          </div>
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Decorator</h2>
              <p>
                This pattern allows behavior to be added to an individual
                object, either statically or dynamically, without affecting the
                behavior of other objects from the same class.
              </p>
            </div>
          </div>
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Facade</h2>
              <p>
                This pattern provides a simplified interface to a complex system
                of classes.
              </p>
            </div>
          </div>
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Flyweight</h2>
              <p>
                This pattern is used to minimize the number of objects created,
                to decrease memory usage and increase performance.
              </p>
            </div>
          </div>
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Proxy</h2>
              <p>
                This pattern provides a surrogate or placeholder object, which
                references an underlying object.
              </p>
            </div>
          </div>
        </div>
      </div>
    </>
  );
};

export default StructuralPatterns;
EOF
git add $FILE

FILE=src/pages/Learn/DesignPatterns/DesignPatterns.tsx
cat > $FILE << EOF
import { Breadcrumb, Nav } from "react-bootstrap";
import { Link } from "react-router-dom";

const DesignPatterns = () => {
  return (
    <>
      <div className="p-5 mb-4 bg-light rounded-3">
        <div className="container-fluid py-5">
          <h1 className="display-5 fw-bold">Design Patterns</h1>
          <p className="col-md-8 fs-4">
            Design patterns in computer science are reusable solutions to common
            problems that arise in software development.
          </p>
        </div>
      </div>
      <div className="container px-4 py-2">
        <div className="row">
          <div className="col-12">
            <Breadcrumb>
              <Breadcrumb.Item
                id="breadcrumbs-link-home"
                linkAs={Link}
                linkProps={{ to: "/" }}
              >
                Home
              </Breadcrumb.Item>
              <Breadcrumb.Item
                id="breadcrumbs-link-learn"
                linkAs={Link}
                linkProps={{ to: "/learn" }}
              >
                Learn
              </Breadcrumb.Item>
              <Breadcrumb.Item active>Design Patterns</Breadcrumb.Item>
            </Breadcrumb>
          </div>
        </div>
      </div>
      <div className="container px-4 py-2">
        <div className="row">
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Creational Patterns</h2>
              <p>
                These patterns are focused on object creation mechanisms, trying
                to create objects in a manner suitable to the situation.
              </p>
              <Nav.Link
                as={Link}
                className="btn btn-outline-secondary"
                id="cards-link-creational-patterns"
                to="/learn/design-patterns/creational-patterns"
                type="button"
              >
                Learn
              </Nav.Link>
            </div>
          </div>
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Structural Patterns</h2>
              <p>
                These patterns deal with object composition, creating
                relationships between objects to form larger structures.
              </p>
              <Nav.Link
                as={Link}
                className="btn btn-outline-secondary"
                id="cards-link-structural-patterns"
                to="/learn/design-patterns/structural-patterns"
                type="button"
              >
                Learn
              </Nav.Link>
            </div>
          </div>
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Behavioral Patterns</h2>
              <p>
                These patterns are focused on communication between objects,
                what goes on between objects and how they operate together.
              </p>
              <Nav.Link
                as={Link}
                className="btn btn-outline-secondary"
                id="cards-link-behavioral-patterns"
                to="/learn/design-patterns/behavioral-patterns"
                type="button"
              >
                Learn
              </Nav.Link>
            </div>
          </div>
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Concurrency Patterns</h2>
              <p>
                These patterns are focused on managing concurrent access to
                shared resources and addressing issues that arise in concurrent
                computing.
              </p>
              <Nav.Link
                as={Link}
                className="btn btn-outline-secondary"
                id="cards-link-concurrency-patterns"
                to="/learn/design-patterns/concurrency-patterns"
                type="button"
              >
                Learn
              </Nav.Link>
            </div>
          </div>
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Architectural Patterns</h2>
              <p>
                These patterns are focused on overall software architecture, and
                high-level structural organization of code.
              </p>
              <Nav.Link
                as={Link}
                className="btn btn-outline-secondary"
                id="cards-link-architectural-patterns"
                to="/learn/design-patterns/architectural-patterns"
                type="button"
              >
                Learn
              </Nav.Link>
            </div>
          </div>
        </div>
      </div>
    </>
  );
};

export default DesignPatterns;
EOF
git add $FILE

mkdir -p src/pages/Learn/Principles && echo "Created src/pages/Learn/Principles folder" || exit 1

mkdir -p src/pages/Learn/Principles/SolidPrinciples && echo "Created src/pages/Learn/Principles/SolidPrinciples folder" || exit 1

FILE=src/pages/Learn/Principles/SolidPrinciples/SolidPrinciples.tsx
cat > $FILE << EOF
import { Breadcrumb } from "react-bootstrap";
import { Link } from "react-router-dom";

const SolidPrinciples = () => {
  return (
    <>
      <div className="p-5 mb-4 bg-light rounded-3">
        <div className="container-fluid py-5">
          <h1 className="display-5 fw-bold">SOLID Principles</h1>
          <p className="col-md-8 fs-4">
            Five design principles intended to make object-oriented designs more
            understandable, flexible, and maintainable.
          </p>
        </div>
      </div>
      <div className="container px-4 py-2">
        <div className="row">
          <div className="col-12">
            <Breadcrumb>
              <Breadcrumb.Item
                id="breadcrumbs-link-home"
                linkAs={Link}
                linkProps={{ to: "/" }}
              >
                Home
              </Breadcrumb.Item>
              <Breadcrumb.Item
                id="breadcrumbs-link-learn"
                linkAs={Link}
                linkProps={{ to: "/learn" }}
              >
                Learn
              </Breadcrumb.Item>
              <Breadcrumb.Item
                id="breadcrumbs-link-principles"
                linkAs={Link}
                linkProps={{ to: "/learn/principles" }}
              >
                Principles
              </Breadcrumb.Item>
              <Breadcrumb.Item active>SOLID Principles</Breadcrumb.Item>
            </Breadcrumb>
          </div>
        </div>
      </div>
      <div className="container px-4 py-2">
        <div className="row">
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Single-Responsibility Principle</h2>
              <p>
                There should never be more than one reason for a class to
                change.
              </p>
            </div>
          </div>
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Open-Closed Principle</h2>
              <p>
                Software entities should be open for extension, but closed for
                modification.
              </p>
            </div>
          </div>
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Liskov Substitution Principle</h2>
              <p>
                Linked lists are a sequence of things where a thing can be added
                to or removed from any location.
              </p>
            </div>
          </div>
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Interface Segregation Principle</h2>
              <p>
                Clients should not be forced to depend upon interfaces that they
                do not use.
              </p>
            </div>
          </div>
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Dependency Inversion Principle</h2>
              <p>Depend upon abstractions, not concretions.</p>
            </div>
          </div>
        </div>
      </div>
    </>
  );
};

export default SolidPrinciples;
EOF
git add $FILE

FILE=src/pages/Learn/Principles/Principles.tsx
cat > $FILE << EOF
import { Breadcrumb, Nav } from "react-bootstrap";
import { Link } from "react-router-dom";

const Principles = () => {
  return (
    <>
      <div className="p-5 mb-4 bg-light rounded-3">
        <div className="container-fluid py-5">
          <h1 className="display-5 fw-bold">Principles</h1>
          <p className="col-md-8 fs-4">Learn about principles like SOLID.</p>
        </div>
      </div>
      <div className="container px-4 py-2">
        <div className="row">
          <div className="col-12">
            <Breadcrumb>
              <Breadcrumb.Item
                id="breadcrumbs-link-home"
                linkAs={Link}
                linkProps={{ to: "/" }}
              >
                Home
              </Breadcrumb.Item>
              <Breadcrumb.Item
                id="breadcrumbs-link-learn"
                linkAs={Link}
                linkProps={{ to: "/learn" }}
              >
                Learn
              </Breadcrumb.Item>
              <Breadcrumb.Item active>Principles</Breadcrumb.Item>
            </Breadcrumb>
          </div>
        </div>
      </div>
      <div className="container px-4 py-2">
        <div className="row">
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>SOLID Principles</h2>
              <p>
                Five design principles intended to make object-oriented designs
                more understandable, flexible, and maintainable.
              </p>
              <Nav.Link
                as={Link}
                className="btn btn-outline-secondary"
                id="cards-link-solid-principles"
                to="/learn/principles/solid-principles"
                type="button"
              >
                Learn
              </Nav.Link>
            </div>
          </div>
        </div>
      </div>
    </>
  );
};

export default Principles;
EOF
git add $FILE

FILE=src/pages/Learn/Learn.tsx
cat > $FILE << EOF
import { Breadcrumb, Nav } from "react-bootstrap";
import { Link } from "react-router-dom";

const Learn = () => {
  return (
    <>
      <div className="p-5 mb-1 bg-light rounded-3">
        <div className="container-fluid py-5">
          <h1 className="display-5 fw-bold">Let's Learn</h1>
          <p className="col-md-8 fs-4">
            Use these series of lessons for learning the fundamentals of
            Computer Science. We'll go through the basics of programming, data
            structures, and algorithms. We'll also go through the best practices
            for software development, including SOLID priciples and Test-Driven
            Development.
          </p>
        </div>
      </div>
      <div className="container px-4 py-2">
        <div className="row">
          <div className="col-12">
            <Breadcrumb>
              <Breadcrumb.Item
                id="breadcrumbs-link-home"
                linkAs={Link}
                linkProps={{ to: "/" }}
              >
                Home
              </Breadcrumb.Item>
              <Breadcrumb.Item active>Learn</Breadcrumb.Item>
            </Breadcrumb>
          </div>
        </div>
      </div>
      <div className="container px-4 py-2">
        <div className="row">
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Data Structures</h2>
              <p>
                Data structures are structures used to organize and store data
                in a computer so that it can be accessed and used efficiently.
              </p>
              <Nav.Link
                as={Link}
                className="btn btn-outline-secondary"
                id="cards-link-data-structures"
                to="/learn/data-structures"
                type="button"
              >
                Learn
              </Nav.Link>
            </div>
          </div>
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Algorithms</h2>
              <p>
                An algorithm is a set of steps to solve a specific problem. In
                computer science, algorithms are used to process data, sort and
                search information, and make decisions.
              </p>
              <Nav.Link
                as={Link}
                className="btn btn-outline-secondary"
                id="cards-link-algorithms"
                to="/learn/algorithms"
                type="button"
              >
                Learn
              </Nav.Link>
            </div>
          </div>
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Design Patterns</h2>
              <p>
                Learn about design patterns such as creational patterns
                (Singleton, Builder, and Factory), behavioral patterns (Iterator
                and Observer), and structural patterns (Decorator).
              </p>
              <Nav.Link
                as={Link}
                className="btn btn-outline-secondary"
                id="cards-link-design-patterns"
                to="/learn/design-patterns"
                type="button"
              >
                Learn
              </Nav.Link>
            </div>
          </div>
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Principles</h2>
              <p>Learn about principles like SOLID.</p>
              <Nav.Link
                as={Link}
                className="btn btn-outline-secondary"
                id="cards-link-principles"
                to="/learn/principles"
                type="button"
              >
                Learn
              </Nav.Link>
            </div>
          </div>
          <div className="col-lg-4 col-md-6 col-sm-12 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Best Practices</h2>
              <p>Learn about best practices like Test-Driven Development.</p>
              <Nav.Link
                as={Link}
                className="btn btn-outline-secondary"
                id="cards-link-best-practices"
                to="/learn/best-practices"
                type="button"
              >
                Learn
              </Nav.Link>
            </div>
          </div>
        </div>
      </div>
    </>
  );
};

export default Learn;
EOF
git add $FILE

FILE=src/pages/About.tsx
cat > $FILE << EOF
const Home = () => {
  return (
    <>
      <div className="container col-xxl-8 px-4 py-5">
        <div className="row flex-lg-row align-items-center g-5 py-5">
          <div className="col-lg-6">
            <h1>OLIVER FORRAL</h1>
            <p className="lead">
              Forward-thinking engineer with a comprehensive range of
              development experience and an appetite for solving problems.
              Committed to team environments and the ability to pick up any new
              technology. Enjoys collaboration, communication, as well as
              mentoring other engineers.
            </p>
          </div>
          <div className="col-10 col-sm-8 col-lg-6">
            <ul className="list-group mx-0 w-auto">
              <li className="list-group-item d-flex gap-2">
                <a
                  className="nav-link"
                  href="https://www.linkedin.com/in/$USER/"
                >
                  <i className="fa-brands fa-linkedin"></i> -
                  linkedin.com/in/$USER
                </a>
              </li>
              <li className="list-group-item d-flex gap-2">
                <a className="nav-link" href="https://github.com/$USER">
                  <i className="fa-brands fa-github"></i> - github.com/$USER
                </a>
              </li>
              <li className="list-group-item d-flex gap-2">
                <a className="nav-link" href="https://twitter.com/$USER">
                  <i className="fa-brands fa-twitter"></i> -
                  twitter.com/$USER
                </a>
              </li>
              <li className="list-group-item d-flex gap-2">
                <a
                  className="nav-link"
                  href="https://www.facebook.com/$USER"
                >
                  <i className="fa-brands fa-facebook"></i> -
                  facebook.com/$USER
                </a>
              </li>
              <li className="list-group-item d-flex gap-2">
                <a className="nav-link" href="mailto:$USER@gmail.com">
                  <i className="fa-solid fa-envelope"></i> - $USER@gmail.com
                </a>
              </li>
              <li className="list-group-item d-flex gap-2">
                <a
                  className="nav-link"
                  href="https://www.facebook.com/$USER"
                >
                  <i className="fa-solid fa-phone"></i> - (503) 750-4562
                </a>
              </li>
            </ul>
          </div>
        </div>
      </div>
      <div className="container col-xxl-8 px-4 py-5">
        <div className="row flex-lg-row align-items-center g-5 py-5">
          <div className="container">
            <h2 className="text-center">EXPERIENCE</h2>
            <div className="row g-5 py-5">
              <div className="col-12">
                <h3>ENERFLO - SOFTWARE ENGINEER</h3>
                <p className="text-end">MAY 2022 - PRESENT</p>
                <p>
                  Utilized a wide range of full-stack capabilities at a startup
                  with a very lean team. Worked on a variety of projects,
                  including a Laravel SaaS and a NodeJS API.
                </p>
                <div>
                  <h5>ACCOMPLISHMENTS</h5>
                  <ul>
                    <li>
                      Fixed bugs that found themselves in production and wrote
                      tests to prevent them from happening again.
                    </li>
                  </ul>
                </div>
              </div>
            </div>
            <div className="row g-5 py-5">
              <div className="col-12">
                <h3>FREELANCE - SOFTWARE ENGINEER</h3>
                <p className="text-end">SEPTEMBER 2021 - MAY 2022</p>
                <p>
                  Provided freelance work for small local companies that needed
                  web development and custom-made systems tools. Became more
                  familiar with Digital Ocean's offerings, including
                  provisioning App, Droplets, and Spaces. Increased proficiency
                  in Rust using Actix Web for the backend and Dioxus for both
                  desktop and web front end.
                </p>
                <div>
                  <h5>ACCOMPLISHMENTS</h5>
                  <ul>
                    <li>
                      Created command-line tools that saved hours each week for
                      each employee using them.
                    </li>
                  </ul>
                </div>
              </div>
            </div>
            <div className="row g-5 py-5">
              <div className="col-12">
                <h3>INCOMM INCENTIVES - SOFTWARE ENGINEER</h3>
                <p className="text-end">JUNE 2017 - SEPTEMBER 2021</p>
                <p>
                  Configured continuous integrations with TeamCity. Developed
                  code for automating deploys into AWS S3 buckets. Implemented
                  several REST microservices in C# and .NET Core, as well as
                  front ends in TypeScript and React. Exposed to New Relic for
                  logging and Octopus Deploy for deployment. Supported new
                  engineers with getting up to speed with best practices.
                  Mentored coworkers that wanted to move into software
                  engineering.
                </p>
                <div>
                  <h5>ACCOMPLISHMENTS</h5>
                  <ul>
                    <li>
                      Championed small experiments within the team, such as
                      doing mini-hackathons. These experiments have generated
                      greater creativity and innovation among team members.
                    </li>
                    <li>
                      Collaborated closely with UX Engineer to design a
                      TypeScript React component library that can be used
                      company-wide. By giving the company more control,
                      employees are able to save time and money maintaining
                      consistent WCAG and ADA compliant user interfaces across
                      all front ends.
                    </li>
                    <li>
                      A key player in helping a recent acquisition with their
                      backlog of new features and the refactoring of old
                      features that an important client was requesting.
                      Successfully implemented the changes, which maintained the
                      professional relationship with the client.
                    </li>
                  </ul>
                </div>
              </div>
            </div>
            <div className="row g-5 py-5">
              <div className="col-12">
                <h3>
                  MULTNOMAH EDUCATION SERVICE DISTRICT - APPLICATION DEVELOPER
                </h3>
                <p className="text-end">OCTOBER 2009 - JUNE 2017</p>
                <p>
                  Maintained legacy applications in jQuery and updated some
                  applications to React and Ember. Maintained part of Oracle
                  database and updated applications to use PostgreSQL for
                  production data and SQLite for performant mock testing.
                  Maintained multiple legacy applications in PHP and updated
                  applications to use REST and Symfony, which used PHP 7 and
                  actual coding standards. Implemented multiple applications in
                  Symfony and Bootstrap. Configured continuous integration with
                  TravisCI. Creatively solved the logistics of implementing
                  complex business rules.
                </p>
                <div>
                  <h5>ACCOMPLISHMENTS</h5>
                  <ul>
                    <li>
                      Converted projects from Subversion to Git and put them
                      into GitHub. As a result, the team became more
                      collaborative and completed work more efficiently.
                    </li>
                    <li>
                      Became an expert in using Symfony for all refactors and
                      new development. This also resulted in the team being more
                      collaborative and getting work done more efficiently.
                    </li>
                    <li>
                      After the company had run out of symbols in an old
                      off-the-shelf product, took initiative and coded a script
                      that recalculated and updated the database so it used only
                      10 symbols. This allowed us to save time and money by
                      using the old product while it was systematically
                      replaced.
                    </li>
                  </ul>
                </div>
              </div>
            </div>
            <div className="row g-5 py-5">
              <div className="col-12">
                <h3>MILES CONSULTING, INC. - WEB APPLICATION DEVELOPER</h3>
                <p className="text-end">MARCH 2007 - DECEMBER 2012</p>
                <p>
                  Constructed and maintained an enterprise web application in
                  JavaScript, which requests API calls to a C# and ASP.Net
                  backend which then connects to an SQL Server database.
                </p>
                <div>
                  <h5>ACCOMPLISHMENTS</h5>
                  <ul>
                    <li>
                      The sole developer during this internship, was able to
                      teach self how to turn a set of requirements into a
                      full-stack web application while also learning C# and SQL
                      Server.
                    </li>
                  </ul>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
      <div className="container col-xxl-8 px-4 py-5">
        <div className="row flex-lg-row align-items-center g-5 py-5">
          <div>
            <h2 className="text-center">EDUCATION</h2>
            <div>
              <div>
                <h3>Oregon State University</h3>
                <div>Bachelor of Science</div>
                <div>Computer Science - Information Systems Track</div>
              </div>
              <div>
                <span>Graduated June 2009</span>
              </div>
            </div>
          </div>
        </div>
      </div>
      <div className="container col-xxl-8 px-4 py-5">
        <div className="row flex-lg-row align-items-center g-5 py-5">
          <div className="col-12">
            <h2 className="text-center">SKILLS</h2>
            <h3>Programming Languages & Tools</h3>
            <ul className="list-group">
              <li className="list-group-item">
                <i className="fa-brands fa-js"></i> - JavaScript - 15 years
              </li>
              <li className="list-group-item">
                <i className="fa-brands fa-php"></i> - PHP - 15 years
              </li>
              <li className="list-group-item">
                <i className="fa-solid fa-database"></i> - Postgres - 15 years
              </li>
              <li className="list-group-item">
                <i className="fa-brands fa-git"></i> - Git - 15 years
              </li>
              <li className="list-group-item">
                <i className="fa-brands fa-github"></i> - GitHub - 15 years
              </li>
              <li className="list-group-item">
                <i className="fa-solid fa-database"></i> - SQLite - 14 years
              </li>
              <li className="list-group-item">
                <i className="fa-brands fa-bootstrap"></i> - Bootstrap - 10
                years
              </li>
              <li className="list-group-item">
                <i className="fa-brands fa-docker"></i> - Docker - 9 years
              </li>
              <li className="list-group-item">
                <i className="fa-brands fa-react"></i> - React - 8 years
              </li>
              <li className="list-group-item">
                <i className="fa-brands fa-js"></i> - TypeScript - 7 years
              </li>
              <li className="list-group-item">
                <i className="fa-brands fa-symfony"></i> - Symfony - 7 years
              </li>
              <li className="list-group-item">
                <i className="fa-solid fa-database"></i> - Oracle - 7 years
              </li>
              <li className="list-group-item">
                <i className="fa-brands fa-js"></i> - JQuery - 6 years
              </li>
              <li className="list-group-item">
                <i className="fa-brands fa-microsoft"></i> - C# - 6 years
              </li>
              <li className="list-group-item">
                <i className="fa-solid fa-database"></i> - SQL Server - 5 years
              </li>
              <li className="list-group-item">
                <i className="fa-brands fa-microsoft"></i> - .NET - 5 years
              </li>
              <li className="list-group-item">
                <i className="fa-solid fa-database"></i> - RavenDB - 4 years
              </li>
              <li className="list-group-item">
                <i className="fa-brands fa-aws"></i> - AWS - 4 years
              </li>
              <li className="list-group-item">
                <i className="fa-brands fa-microsoft"></i> - Azure - 4 years
              </li>
              <li className="list-group-item">
                <i className="fa-brands fa-octopus-deploy"></i> - Octopus Deploy
                - 4 years
              </li>
              <li className="list-group-item">
                <i className="fa-brands fa-digital-ocean"></i> - Digital Ocean -
                2 years
              </li>
              <li className="list-group-item">
                <i className="fa-brands fa-rust"></i> - Rust - 1 year
              </li>
              <li className="list-group-item">
                <i className="fa-brands fa-rust"></i> - Actix Web - 1 year
              </li>
              <li className="list-group-item">
                <i className="fa-solid fa-database"></i> - Redis - 1 year
              </li>
            </ul>
          </div>
          <div className="col-12">
            <h3>Workflow</h3>
            <ul className="list-group">
              <li className="list-group-item">
                <span>
                  <i className="fa-solid fa-check"></i>
                </span>
                Mobile-First, Responsive Design
              </li>
              <li className="list-group-item">
                <span>
                  <i className="fa-solid fa-check"></i>
                </span>
                Cross Browser Testing & Debugging
              </li>
              <li className="list-group-item">
                <span>
                  <i className="fa-solid fa-check"></i>
                </span>
                Cross Functional Teams
              </li>
              <li className="list-group-item">
                <span>
                  <i className="fa-solid fa-check"></i>
                </span>
                Agile Development & Scrum
              </li>
            </ul>
          </div>
        </div>
      </div>
    </>
  );
};

export default Home;
EOF
git add $FILE

FILE=src/pages/Home.tsx
cat > $FILE << EOF
import { Nav } from "react-bootstrap";
import { Link } from "react-router-dom";

const Home = () => {
  return (
    <>
      <div className="p-5 mb-4 bg-light rounded-3">
        <div className="container-fluid py-5">
          <h1 className="display-5 fw-bold">intrepion</h1>
          <p className="col-md-8 fs-4">
            Your resource for learning how to create software
          </p>
        </div>
      </div>
      <div className="container px-4 py-2">
        <div className="row">
          <div className="col-md-6 py-2">
            <div className="h-100 p-5 bg-light border rounded-3">
              <h2>Let's Learn</h2>
              <p>
                Use these series of lessons for learning the fundamentals of
                Computer Science. We'll go through the basics of programming,
                data structures, and algorithms. We'll also go through the best
                practices for software development, including SOLID priciples
                and Test-Driven Development.
              </p>
              <Nav.Link
                as={Link}
                className="btn btn-outline-secondary"
                id="cards-link-learn"
                to="/learn"
                type="button"
              >
                Learn
              </Nav.Link>
            </div>
          </div>
        </div>
      </div>
    </>
  );
};

export default Home;
EOF
git add $FILE


FILE=src/pages/NotFound.tsx
cat > $FILE << EOF
const NotFound = () => {
  return (
    <>
      <div className="p-5 mb-4 bg-light rounded-3">
        <div className="container-fluid py-5">
          <h1 className="display-5 fw-bold">Not Found</h1>
          <p className="col-md-8 fs-4">Whoops! You've found a broken link!</p>
        </div>
      </div>
    </>
  );
};

export default NotFound;
EOF
git add $FILE

mkdir -p src/utilities && echo "Created src/utilities folder" || exit 1

FILE=src/utilitiesga4.ts
cat > $FILE << EOF
import ga4 from "react-ga4";

const isProduction = process.env.NODE_ENV === "production";

export const init = (GOOGLE_ANALYTICS_ID: string) =>
  ga4.initialize(GOOGLE_ANALYTICS_ID, {
    testMode: !isProduction,
  });

export const sendEvent = (name: string) =>
  ga4.event("screen_view", {
    app_name: "myApp",
    screen_name: name,
  });

export const sendPageview = (path: string) =>
  ga4.send({
    hitType: "pageview",
    page: path,
  });
EOF
git add $FILE

FILE=src/utilities/useAnalytics.ts
cat > $FILE << EOF
import { useEffect } from "react";
import { useLocation } from "react-router-dom";

import * as analytics from "./ga4";

export function useAnalytics() {
  const GOOGLE_ANALYTICS_ID = process.env.REACT_APP_GOOGLE_ANALYTICS_ID ?? "";
  const location = useLocation();

  useEffect(() => {
    if (GOOGLE_ANALYTICS_ID) {
      analytics.init(GOOGLE_ANALYTICS_ID);
    }
  }, [GOOGLE_ANALYTICS_ID]);

  useEffect(() => {
    if (GOOGLE_ANALYTICS_ID) {
      const path = location.pathname + location.search;
      analytics.sendPageview(path);
    }
  }, [location, GOOGLE_ANALYTICS_ID]);
}

export default useAnalytics;
EOF
git add $FILE

FILE=src/App.tsx
cat > $FILE << EOF
import { BrowserRouter } from "react-router-dom";
import Routing from "./Routing";

function App() {
  return (
    <BrowserRouter>
      <Routing />
    </BrowserRouter>
  );
}

export default App;
EOF
git add $FILE

FILE=src/AuthProvider.tsx
cat > $FILE << EOF
import { createContext, useState, FC, ReactNode, useEffect } from "react";

const SERVER_URL = process.env.REACT_APP_SERVER_URL ?? "";

type AuthContextState = {
  authenticatedUserName: string;
  serverUrl: string;
  setAuthenticatedUserName: (authenticatedUserName: string) => void;
};

const contextDefaultValues: AuthContextState = {
  authenticatedUserName: "",
  setAuthenticatedUserName: function (authenticatedUserName: string): void {
    throw new Error("Function not implemented.");
  },
  serverUrl: "",
};

export const AuthContext =
  createContext<AuthContextState>(contextDefaultValues);

interface Props {
  children: ReactNode;
}

const AuthProvider: FC<Props> = ({ children }) => {
  const [authenticatedUserName, setAuthenticatedUserName] = useState<string>(
    contextDefaultValues.authenticatedUserName
  );

  const serverUrl = SERVER_URL;

  useEffect(() => {
    const authenticatedUserName = localStorage.getItem("authenticatedUserName");

    if (authenticatedUserName) {
      setAuthenticatedUserName(authenticatedUserName);
    }
  }, []);

  useEffect(() => {
    localStorage.setItem("authenticatedUserName", authenticatedUserName);
  }, [authenticatedUserName]);

  return (
    <AuthContext.Provider
      value={{
        authenticatedUserName,
        setAuthenticatedUserName,
        serverUrl,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};

export default AuthProvider;
EOF
git add $FILE

FILE=src/Navigating.tsx
cat > $FILE << EOF
import { useContext } from "react";
import { Container, Nav, Navbar } from "react-bootstrap";
import { Link, Outlet } from "react-router-dom";
import AuthProvider, { AuthContext } from "./AuthProvider";

const Navigating = () => {
  const { authenticatedUserName } = useContext(AuthContext);

  return (
    <>
      <Navbar collapseOnSelect expand="lg" bg="dark" variant="dark">
        <Container>
          <Navbar.Brand as={Link} id="navigations-link-intrepion" to="/">
            intrepion
          </Navbar.Brand>
          <Navbar.Toggle aria-controls="responsive-navbar-nav" />
          <Navbar.Collapse id="responsive-navbar-nav">
            <Nav className="me-auto">
              <Nav.Link as={Link} id="navigations-link-home" to="/">
                Home
              </Nav.Link>
              <Nav.Link as={Link} id="navigations-link-learn" to="/learn">
                Learn
              </Nav.Link>
              <Nav.Link as={Link} id="navigations-link-about" to="/about">
                About
              </Nav.Link>
            </Nav>
            {authenticatedUserName ? (
              <Nav className="text-end">
                <Nav.Link as={Link} id="navigations-link-profile" to="/profile">
                  {authenticatedUserName}
                </Nav.Link>
                <Nav.Link
                  as={Link}
                  id="navigations-link-log-out"
                  to="/authentication/log-out"
                >
                  Log Out
                </Nav.Link>
              </Nav>
            ) : (
              <Nav className="text-end">
                <Nav.Link
                  as={Link}
                  id="navigations-link-log-in"
                  to="/authentication/log-in"
                >
                  Log In
                </Nav.Link>
                <Nav.Link
                  as={Link}
                  id="navigations-link-register"
                  to="/authentication/register"
                >
                  Register
                </Nav.Link>
              </Nav>
            )}
          </Navbar.Collapse>
        </Container>
      </Navbar>
      <main className="container">
        <Outlet />
      </main>
      <div className="container">
        <footer className="py-5">
          <div className="row"></div>
          <div className="d-flex flex-column flex-sm-row justify-content-between py-4 my-4 border-top">
            <p>© 2023 Oliver Forral All rights reserved.</p>
            <ul className="list-unstyled d-flex">
              <li className="ms-3">
                <a
                  className="link-dark"
                  href="https://twitter.com/$USER"
                  id="socials-link-twitter"
                  rel="noopener noreferrer"
                  target="_blank"
                >
                  <i className="fa-brands fa-twitter"></i>
                </a>
              </li>
              <li className="ms-3">
                <a
                  className="link-dark"
                  href="https://www.instagram.com/$USER/"
                  id="socials-link-instagram"
                  rel="noopener noreferrer"
                  target="_blank"
                >
                  <i className="fa-brands fa-instagram"></i>
                </a>
              </li>
              <li className="ms-3">
                <a
                  className="link-dark"
                  href="https://www.facebook.com/$USER"
                  id="socials-link-facebook"
                  rel="noopener noreferrer"
                  target="_blank"
                >
                  <i className="fa-brands fa-facebook"></i>
                </a>
              </li>
            </ul>
          </div>
        </footer>
      </div>
    </>
  );
};

const WrappedNavigating = () => (
  <AuthProvider>
    <Navigating />
  </AuthProvider>
);

export default WrappedNavigating;
EOF
git add $FILE

FILE=src/Routing.tsx
cat > $FILE << EOF
import { Route, Routes } from "react-router-dom";
import About from "./pages/About";
import Home from "./pages/Home";
import Algorithms from "./pages/Learn/Algorithms/Algorithms";
import BestPractices from "./pages/Learn/BestPractices/BestPractices";
import DataStructures from "./pages/Learn/DataStructures/DataStructures";
import ArchitecturalPatterns from "./pages/Learn/DesignPatterns/ArchitecturalPatterns/ArchitecturalPatterns";
import BehavioralPatterns from "./pages/Learn/DesignPatterns/BehavioralPatterns/BehavioralPatterns";
import ConcurrencyPatterns from "./pages/Learn/DesignPatterns/ConcurrencyPatterns/ConcurrencyPatterns";
import CreationalPatterns from "./pages/Learn/DesignPatterns/CreationalPatterns/CreationalPatterns";
import DesignPatterns from "./pages/Learn/DesignPatterns/DesignPatterns";
import StructuralPatterns from "./pages/Learn/DesignPatterns/StructuralPatterns/StructuralPatterns";
import Learn from "./pages/Learn/Learn";
import Principles from "./pages/Learn/Principles/Principles";
import SolidPrinciples from "./pages/Learn/Principles/SolidPrinciples/SolidPrinciples";
import LogIn from "./pages/Authentication/LogIn";
import LogOut from "./pages/Authentication/LogOut";
import Navigating from "./Navigating";
import NotFound from "./pages/NotFound";
import Register from "./pages/Authentication/Register";
import useAnalytics from "./utilities/useAnalytics";

function Routing() {
  useAnalytics();

  return (
    <Routes>
      <Route element={<Navigating />}>
        <Route index element={<Home />} />
        <Route path="about" element={<About />} />
        <Route path="authentication">
          <Route path="log-in" element={<LogIn />} />
          <Route path="log-out" element={<LogOut />} />
          <Route path="register" element={<Register />} />
        </Route>
        <Route path="home" element={<Home />} />
        <Route path="learn">
          <Route index element={<Learn />} />
          <Route path="algorithms" element={<Algorithms />} />
          <Route path="best-practices" element={<BestPractices />} />
          <Route path="data-structures" element={<DataStructures />} />
          <Route path="design-patterns">
            <Route index element={<DesignPatterns />} />
            <Route
              path="architectural-patterns"
              element={<ArchitecturalPatterns />}
            />
            <Route
              path="behavioral-patterns"
              element={<BehavioralPatterns />}
            />
            <Route
              path="concurrency-patterns"
              element={<ConcurrencyPatterns />}
            />
            <Route
              path="creational-patterns"
              element={<CreationalPatterns />}
            />
            <Route
              path="structural-patterns"
              element={<StructuralPatterns />}
            />
          </Route>
          <Route path="principles">
            <Route index element={<Principles />} />
            <Route path="solid-principles" element={<SolidPrinciples />} />
          </Route>
        </Route>
        <Route path="*" element={<NotFound />} />
      </Route>
    </Routes>
  );
}

export default Routing;
EOF
git add $FILE

npx cypress run && git commit --message="green - test routes" || exit 1
npx prettier --write .
git add --all
git commit --message "npx prettier --write ."

git push --force

cd ..

killall -15 node
