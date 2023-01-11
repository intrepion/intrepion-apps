#!/usr/bin/env bash

SCRIPT=$0

echo " - Running $SCRIPT"

pushd .

cd ..
pwd

CLIENT="http://localhost:3000"
CONTRACT=session-json-rpc
CLIENT_FRAMEWORK=typescript-react
CLIENT_TEMPLATE=typescript
KEBOB=quiz
PASCAL=Quiz
SERVER_FRAMEWORK=csharp-dotnet
SERVER_TEMPLATE=webapi

CLIENT_CONTRACT=$CONTRACT-client-web
SOLUTION=${PASCAL}App
SERVER_CONTRACT=$CONTRACT-server

CLIENT_REPOSITORY=intrepion-$KEBOB-$CLIENT_CONTRACT-$CLIENT_FRAMEWORK-$CLIENT_TEMPLATE
PROJECT=$SOLUTION.WebApi
SERVER_REPOSITORY=intrepion-$KEBOB-$SERVER_CONTRACT-$SERVER_FRAMEWORK-$SERVER_TEMPLATE

if [ ! -d "$SERVER_REPOSITORY" ]; then
  git clone git@github.com:intrepion/$SERVER_REPOSITORY.git
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

FILE=$SOLUTION.Tests/UnitTest1.cs
rm -rf $FILE
git add $FILE

FOLDER=$SOLUTION.WebApi/Controllers
rm -rf $FOLDER
git add $FOLDER

FILE=$SOLUTION.WebApi/WeatherForecast.cs
rm -rf $FILE
git add $FILE
git commit --message="Removed boilerplate."

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
dotnet run --project $PROJECT
\`\`\`
EOF
git add $FILE
git commit -m "Added commands section to README file.";

mkdir -p .github/workflows

FILE=.github/workflows/dotnet.yml
cat > $FILE << EOF
# This workflow will build a .NET project
# For more information see: https://docs.github.com/en/actions/automating-builds-and-tests/building-and-testing-net

name: .NET

on:
  push:
    branches: [ "main" ]
  pull_request:
    branches: [ "main" ]

jobs:
  build:

    runs-on: ubuntu-latest

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

[![.NET](https://github.com/intrepion/$REPOSITORY/actions/workflows/dotnet.yml/badge.svg?branch=main)](https://github.com/intrepion/$REPOSITORY/actions/workflows/dotnet.yml)
EOF
git add $FILE
git commit --message="Added GitHub Action files."

mkdir -p .do

FILE=.do/app.yaml
cat > $FILE << EOF
name: $KEBOB-$SERVER_CONTRACT
region: sfo
services:
  - dockerfile_path: Dockerfile
    github:
      branch: main
      deploy_on_push: true
      repo: intrepion/$SERVER_REPOSITORY
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
        repo: intrepion/$SERVER_REPOSITORY
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

COPY $SOLUTION.App.sln .
COPY $SOLUTION.Library/*.csproj ./$SOLUTION.Library/
COPY $SOLUTION.Tests/*.csproj ./$SOLUTION.Tests/
COPY $PROJECT/*.csproj ./$PROJECT/
RUN dotnet restore

COPY $SOLUTION.Library/. ./$SOLUTION.Library/
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

[![Deploy to DO](https://www.deploytodo.com/do-btn-blue.svg)](https://cloud.digitalocean.com/apps/new?repo=https://github.com/intrepion/$SERVER_REPOSITORY/tree/main)
EOF
git add $FILE

mkdir scripts

FILE=scripts/docker_build.sh
cat > $FILE << EOF
#!/usr/bin/env bash

sudo docker build --tag $SERVER_REPOSITORY --file Dockerfile .
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

FILE=scripts/dotnet_watch.sh
cat > $FILE << EOF
#!/usr/bin/env bash

dotnet watch test --project $SOLUTION.Tests
EOF

chmod +x $FILE
git add $FILE
git commit --message="Added Digital Ocean files."

mkdir -p $SOLUTION.Tests/WebApi/HealthCheck

FILE=$SOLUTION.Tests/WebApi/HealthCheck/TestHealthCheckController.cs
cat > $FILE << EOF
namespace QuizApp.Tests.WebApi.HealthCheck;

public class TestHealthCheckController
{
    [Fact]
    public void Get_Returns200()
    {
        // Arrange
        var controller = new HealthCheckController();
    }
}
EOF
git add $FILE
git commit --message="red - testing the health check controller for 200 status"
dotnet test

mkdir -p $SOLUTION.WebApi/HealthCheck

FILE=$SOLUTION.WebApi/HealthCheck/HealthCheckController.cs
cat > $FILE << EOF
namespace QuizApp.WebApi.HealthCheck;

public class HealthCheckController {}
EOF
git add $FILE

FILE=$SOLUTION.Tests/WebApi/HealthCheck/TestHealthCheckController.cs
cat > $FILE << EOF
using QuizApp.WebApi.HealthCheck;

namespace QuizApp.Tests.WebApi.HealthCheck;

public class TestHealthCheckController
{
    [Fact]
    public void Get_Returns200()
    {
        // Arrange
        var controller = new HealthCheckController();
    }
}
EOF
git add $FILE
git commit --message="green - testing the health check controller for 200 status"
dotnet test

FILE=$SOLUTION.Tests/WebApi/HealthCheck/TestHealthCheckController.cs
cat > $FILE << EOF
using QuizApp.WebApi.HealthCheck;

namespace QuizApp.Tests.WebApi.HealthCheck;

public class TestHealthCheckController
{
    [Fact]
    public void Get_Returns200()
    {
        // Arrange
        var controller = new HealthCheckController();

        // Act
        var actualResult = controller.Get();
    }
}
EOF
git add $FILE
git commit --message="red - trying to use the get endpoint"
dotnet test

FILE=$SOLUTION.WebApi/HealthCheck/HealthCheckController.cs
cat > $FILE << EOF
namespace QuizApp.WebApi.HealthCheck;

public class HealthCheckController
{
    public string Get()
    {
        return "";
    }
}
EOF
git add $FILE
git commit --message="green - trying to use the get endpoint"
dotnet test

FILE=$SOLUTION.Tests/WebApi/HealthCheck/TestHealthCheckController.cs
cat > $FILE << EOF
using QuizApp.WebApi.HealthCheck;

namespace QuizApp.Tests.WebApi.HealthCheck;

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
        actualResult.StatusCode.Should().Be(200);
    }
}
EOF
git add $FILE
git commit --message="red - using fluent assertions to check the status code"
dotnet test

FILE=$SOLUTION.Tests/WebApi/HealthCheck/TestHealthCheckController.cs
cat > $FILE << EOF
using FluentAssertions;
using Microsoft.AspNetCore.Mvc;
using QuizApp.WebApi.HealthCheck;

namespace QuizApp.Tests.WebApi.HealthCheck;

public class TestHealthCheckController
{
    [Fact]
    public async void Get_Returns200()
    {
        // Arrange
        var controller = new HealthCheckController();

        // Act
        var actualResult = await controller.Get();
        
        // Assert
        actualResult.Should().BeOfType<OkObjectResult>();
    }
}
EOF
git add $FILE

FILE=$SOLUTION.WebApi/HealthCheck/HealthCheckController.cs
cat > $FILE << EOF
using Microsoft.AspNetCore.Mvc;

namespace QuizApp.WebApi.HealthCheck;

public class HealthCheckController : ControllerBase
{
    public async Task<IActionResult> Get()
    {
        return Ok("");
    }
}
EOF
git add $FILE
git commit --message="green - using fluent assertions to check the status code"
dotnet test

git push --force

cd ..
