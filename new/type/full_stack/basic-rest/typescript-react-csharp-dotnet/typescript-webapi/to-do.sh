#!/usr/bin/env bash

SCRIPT=$0

echo " - Running $SCRIPT"

killall -15 node

pushd .

cd ..
pwd

CANONICAL="To Do"
CLIENT_URL="http://localhost:3000"
CLIENT_FRAMEWORK=typescript-react
CLIENT_TEMPLATE=typescript
CONTRACT=basic-rest
KEBOB=to-do
PASCAL=ToDo
SERVER_FRAMEWORK=csharp-dotnet
SERVER_TEMPLATE=webapi
SNAKE=to_do

CLIENT_CONTRACT=$CONTRACT-client-web
SOLUTION=${PASCAL}App
SERVER_CONTRACT=$CONTRACT-server

CLIENT_REPOSITORY=intrepion-$KEBOB-$CLIENT_CONTRACT-$CLIENT_FRAMEWORK-$CLIENT_TEMPLATE
PROJECT=$SOLUTION.WebApi
SERVER_REPOSITORY=intrepion-$KEBOB-$SERVER_CONTRACT-$SERVER_FRAMEWORK-$SERVER_TEMPLATE

if [ ! -d "$SERVER_REPOSITORY" ]; then
  git clone git@github.com:intrepion/$SERVER_REPOSITORY.git && echo "Checked out $SERVER_REPOSITORY" || exit 1
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
CLIENT_URL="$CLIENT_URL" dotnet run --project $PROJECT
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
          POSTGRES_DB: intrepion
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

[![.NET](https://github.com/intrepion/$SERVER_REPOSITORY/actions/workflows/dotnet.yml/badge.svg?branch=main)](https://github.com/intrepion/$SERVER_REPOSITORY/actions/workflows/dotnet.yml)
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

[![Deploy to DO](https://www.deploytodo.com/do-btn-blue.svg)](https://cloud.digitalocean.com/apps/new?repo=https://github.com/intrepion/$SERVER_REPOSITORY/tree/main)
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
DB_NAME="\${POSTGRES_DB:=intrepion}"
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

FILE=$PROJECT/appsettings.Development.json
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

FILE=$PROJECT/Authentication/User/UserEntity.cs
cat > $FILE << EOF
using Microsoft.AspNetCore.Identity;

namespace $PROJECT.Authentication.User;

public class UserEntity : IdentityUser<Guid>
{
}
EOF
git add $FILE

FILE=$PROJECT/Authentication/User/MakeUserRequest.cs
cat > $FILE << EOF
namespace $PROJECT.Authentication.User
{
    public class MakeUserRequest
    {
        public string? Confirm { get; set; }
        public string? Email { get; set; }
        public string? Password { get; set; }
        public string? UserName { get; set; }
    }
}
EOF
git add $FILE

mkdir -p $PROJECT/Database && echo "Created $PROJECT/Database folder" || exit 1

FILE=$PROJECT/Database/ApplicationDatabaseContext.cs
cat > $FILE << EOF
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using $PROJECT.Authentication.Role;
using $PROJECT.Authentication.User;

namespace $PROJECT.Database;

public class ApplicationDatabaseContext : IdentityDbContext<UserEntity, RoleEntity, Guid>
{
    public ApplicationDatabaseContext(DbContextOptions<ApplicationDatabaseContext> options) : base(options)
    {
        Database.EnsureCreated();
        DatabaseInitializer.Initialize(this);
    }

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);
    }
}
EOF
git add $FILE

FILE=$PROJECT/Database/DatabaseInitializer.cs
cat > $FILE << EOF
using Microsoft.AspNetCore.Identity;
using $PROJECT.Authentication.Role;
using $PROJECT.Authentication.User;

namespace $PROJECT.Database;

public static class DatabaseInitializer
{
    public static void Initialize(ApplicationDatabaseContext context)
    {
        var email = "intrepion@gmail.com";
        var adminRoleName = "Admin";
        var adminRole = context.Roles.SingleOrDefault(role => role.Name == adminRoleName);
        if (adminRole == null)
        {
            adminRole = new RoleEntity
            {
                Id = Guid.NewGuid(),
                Name = adminRoleName,
            };

            context.Roles.Add(adminRole);
        }

        var adminUserName = "admin";
        var adminUser = context.Users.SingleOrDefault(user => user.UserName == adminUserName);
        if (adminUser == null)
        {
            adminUser = new UserEntity
            {
                ConcurrencyStamp = "b580c17a-4891-4907-a289-896cfe626059",
                Email = email,
                Id = new Guid("0f22ead4-c2dc-47b6-bfa7-53b71524a123"),
                NormalizedEmail = email.ToUpper(),
                NormalizedUserName = adminUserName.ToUpper(),
                PasswordHash = "AQAAAAIAAYagAAAAEPlC3spp0sF663crmvWsH44fEgHdynasZEhBYjpU33qVayBbqo13yhf7nc53TVeXFQ==",
                SecurityStamp = "5VBDAQB4FP22JE6R6TUSZQEG5FK5U346",
                UserName = adminUserName,
            };

            context.Users.Add(adminUser);
        }

        var adminUserRole = context.UserRoles.SingleOrDefault(userRole => userRole.UserId == adminUser.Id && userRole.RoleId == adminRole.Id);
        if (adminUserRole == null)
        {
            context.UserRoles.Add(new IdentityUserRole<Guid>
            {
                RoleId = adminRole.Id,
                UserId = adminUser.Id,
            });
        }

        var regularRoleName = "Regular";
        var regularRole = context.Roles.SingleOrDefault(role => role.Name == regularRoleName);
        if (regularRole == null)
        {
            regularRole = new RoleEntity
            {
                Id = Guid.NewGuid(),
                Name = regularRoleName,
            };

            context.Roles.Add(regularRole);
        }

        var regularUserName = "user";
        var regularUser = context.Users.SingleOrDefault(user => user.UserName == regularUserName);
        if (regularUser == null)
        {
            regularUser = new UserEntity
            {
                ConcurrencyStamp = "29b261a3-8854-47aa-b5db-39d1af4d16b4",
                Email = email,
                Id = new Guid("91e3682b-735a-4da0-8bce-956714313878"),
                NormalizedEmail = email.ToUpper(),
                NormalizedUserName = regularUserName.ToUpper(),
                PasswordHash = "AQAAAAIAAYagAAAAEGjTqPCH6FvDgteBVlUpNmyRuWaNHdwnAls3ATX1IvjGMSQonXFeFvMMo785JsA/4g==",
                SecurityStamp = "7F2WYPUIFN55SQY4LYMC2G56C4MZAUOG",
                UserName = regularUserName,
            };

            context.Users.Add(regularUser);
        }

        var regularUserRole = context.UserRoles.SingleOrDefault(userRole => userRole.UserId == regularUser.Id && userRole.RoleId == regularRole.Id);
        if (regularUserRole == null)
        {
            context.UserRoles.Add(new IdentityUserRole<Guid>
            {
                RoleId = regularRole.Id,
                UserId = regularUser.Id,
            });
        }

        context.SaveChanges();
    }
}
EOF
git add $FILE

dotnet test && git commit --message="green - testing the authentication controllers" || exit 1
dotnet format
git add --all
git commit --message "dotnet format"

git push --force

FILE=$PROJECT/Properties/launchSettings.json
SERVER_URL=$(jq '.profiles.http.applicationUrl' $FILE)

cd ..

if [ ! -d "$CLIENT_REPOSITORY" ]; then
  git clone git@github.com:intrepion/$CLIENT_REPOSITORY.git || exit 1;
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

npm install uuid
git add --all
git commit --message "npm install uuid"

echo {}> .prettierrc.json
git add .prettierrc.json
git commit --message "echo {}> .prettierrc.json"

cp .gitignore .prettierignore
git add .prettierignore
git commit --message "cp .gitignore .prettierignore"

npx prettier --write .
git add --all
git commit --message "npx prettier --write ."

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
REACT_APP_SERVER_URL=$SERVER_URL npm start
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

[![.NET](https://github.com/intrepion/$CLIENT_REPOSITORY/actions/workflows/node.js.yml/badge.svg?branch=main)](https://github.com/intrepion/$CLIENT_REPOSITORY/actions/workflows/node.js.yml)
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
    environment_slug: node-js
    github:
      branch: main
      deploy_on_push: true
      repo: intrepion/$CLIENT_REPOSITORY
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
      environment_slug: node-js
      github:
        branch: main
        deploy_on_push: true
        repo: intrepion/$CLIENT_REPOSITORY
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

[![Deploy to DO](https://www.deploytodo.com/do-btn-blue.svg)](https://cloud.digitalocean.com/apps/new?repo=https://github.com/intrepion/$CLIENT_REPOSITORY/tree/main)
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

git commit --message="Added Digital Ocean files."
npx prettier --write .
git add --all
git commit --message "npx prettier --write ."

mkdir -p src/__test__/authentication && echo "Created src/__test__/authentication folder" || exit 1

FILE=src/__test__/authentication/RegisterForm.test.tsx
cat > $FILE << EOF
import { render, screen } from "@testing-library/react";
import RegisterForm from "../../authentication/RegisterForm";

describe("Registration Form", () => {
  let registerButton: HTMLElement;

  beforeEach(() => {
    render(<RegisterForm />);
    let registerButtonElement = screen.queryByRole("button", {
      name: "Register",
    });
    if (!registerButtonElement) {
      throw new Error("Register Button not found");
    }
    registerButton = registerButtonElement;
  });

  it("has button to register", () => {
    // Arrange

    // Act

    // Assert
    expect(registerButton).toBeInTheDocument();
  });
});
EOF
git add $FILE

npm test -- --watchAll=false && exit 1 || git commit --message="red - add register form button"
npx prettier --write .
git add --all
git commit --message "npx prettier --write ."

mkdir -p src/authentication && echo "Created src/authentication folder" || exit 1

FILE=src/authentication/RegisterForm.tsx
cat > $FILE << EOF
export default function RegisterForm() {
  return <button>Register</button>;
}
EOF
git add $FILE

npm test -- --watchAll=false && git commit --message="green - add register form button" || exit 1
npx prettier --write .
git add --all
git commit --message "npx prettier --write ."

FILE=src/__test__/authentication/RegisterForm.test.tsx
cat > $FILE << EOF
import axios from "axios";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import RegisterForm from "../../authentication/RegisterForm";

describe("Registration Form", () => {
  let registerButton: HTMLElement;

  beforeEach(() => {
    render(<RegisterForm />);
    let registerButtonElement = screen.queryByRole("button", {
      name: "Register",
    });
    if (!registerButtonElement) {
      throw new Error("Register Button not found");
    }
    registerButton = registerButtonElement;
  });

  it("has button to register", () => {
    // Arrange

    // Act

    // Assert
    expect(registerButton).toBeInTheDocument();
  });

  it("displays successful message", async () => {
    // Arrange
    const mockApiCall = jest.fn().mockResolvedValue({
      data: {
        id: "1",
        jsonrpc: "2.0",
        result: {},
      },
    });

    axios.get = mockApiCall;

    // Act
    userEvent.click(registerButton);

    // Assert
    const message = await screen.findByText("Successful registration!");
    expect(message).toBeInTheDocument();
  });
});
EOF
git add $FILE

npm test -- --watchAll=false && exit 1 || git commit --message="red - add register api call"
npx prettier --write .
git add --all
git commit --message "npx prettier --write ."

FILE=src/authentication/RegisterForm.tsx
cat > $FILE << EOF
import axios from "axios";
import { useState } from "react";

export default function Register() {
  const [successMessage, setSuccessMessage] = useState("");

  const handleRegister = async () => {
    try {
      const response = await axios.get($SERVER_URL);
      if (!response.data.error) {
        setSuccessMessage("Successful registration!");
      }
    } catch (error) {}
  };

  return (
    <>
      <button onClick={handleRegister}>Register</button>
      {successMessage && <p>{successMessage}</p>}
    </>
  );
}
EOF
git add $FILE

npm test -- --watchAll=false && git commit --message="green - add register api call" || exit 1
npx prettier --write .
git add --all
git commit --message "npx prettier --write ."

FILE=src/__test__/authentication/RegisterForm.test.tsx
cat > $FILE << EOF
import axios from "axios";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { v4 } from "uuid";
import RegisterForm from "../../authentication/RegisterForm";

describe("Registration Form", () => {
  let confirmInput: HTMLElement;
  let emailInput: HTMLElement;
  let registerButton: HTMLElement;
  let passwordInput: HTMLElement;
  let usernameInput: HTMLElement;

  beforeEach(() => {
    render(<RegisterForm />);
    let confirmInputElement = screen.queryByLabelText("Confirm:");
    if (!confirmInputElement) {
      throw new Error("Confirm Input not found");
    }
    confirmInput = confirmInputElement;

    let emailInputElement = screen.queryByLabelText("Email:");
    if (!emailInputElement) {
      throw new Error("Email Input not found");
    }
    emailInput = emailInputElement;

    let registerButtonElement = screen.queryByRole("button", {
      name: "Register",
    });
    if (!registerButtonElement) {
      throw new Error("Register Button not found");
    }
    registerButton = registerButtonElement;

    let passwordInputElement = screen.queryByLabelText("Password:");
    if (!passwordInputElement) {
      throw new Error("Password Input not found");
    }
    passwordInput = passwordInputElement;

    let usernameInputElement = screen.queryByLabelText("Username:");
    if (!usernameInputElement) {
      throw new Error("Username Input not found");
    }
    usernameInput = usernameInputElement;
  });

  it("has form elements to register", () => {
    // Arrange

    // Act

    // Assert
    expect(confirmInput).toBeInTheDocument();
    expect(emailInput).toBeInTheDocument();
    expect(registerButton).toBeInTheDocument();
    expect(passwordInput).toBeInTheDocument();
    expect(usernameInput).toBeInTheDocument();
  });

  it("displays successful message", async () => {
    // Arrange
    const username = v4();
    const email = v4() + "@" + v4() + ".com";
    const password = v4();

    const mockApiCall = jest.fn().mockResolvedValue({
      data: {
        id: "1",
        jsonrpc: "2.0",
        result: {},
      },
    });

    axios.get = mockApiCall;

    // Act
    userEvent.type(usernameInput, username);
    userEvent.type(emailInput, email);
    userEvent.type(passwordInput, password);
    userEvent.type(confirmInput, password);
    userEvent.click(registerButton);

    const message = await screen.findByText("Successful registration!");
    expect(message).toBeInTheDocument();
  });
});
EOF
git add $FILE

npm test -- --watchAll=false && exit 1 || git commit --message="red - add more register fields"
npx prettier --write .
git add --all
git commit --message "npx prettier --write ."

FILE=src/authentication/RegisterForm.tsx
cat > $FILE << EOF
import axios from "axios";
import { useState } from "react";

export default function Register() {
  const [successMessage, setSuccessMessage] = useState("");

  const handleRegister = async (event: React.SyntheticEvent) => {
    event.preventDefault();
    try {
      const response = await axios.get($SERVER_URL);
      if (response.data.result) {
        setSuccessMessage("Successful registration!");
      }
    } catch (error) {}
  };

  return (
    <form onSubmit={handleRegister}>
      <label htmlFor="username">
        Username:
        <input id="username" type="text" />
      </label>
      <label htmlFor="email">
        Email:
        <input id="email" type="email" />
      </label>
      <label htmlFor="password">
        Password:
        <input id="password" type="password" />
      </label>
      <label htmlFor="confirm">
        Confirm:
        <input id="confirm" type="password" />
      </label>
      <button id="register" type="submit">
        Register
      </button>
      {successMessage && <p>{successMessage}</p>}
    </form>
  );
}
EOF
git add $FILE

npm test -- --watchAll=false && git commit --message="green - add more register fields" || exit 1
npx prettier --write .
git add --all
git commit --message "npx prettier --write ."

FILE=src/__test__/authentication/RegisterForm.test.tsx
cat > $FILE << EOF
import axios from "axios";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { v4 } from "uuid";
import RegisterForm from "../../authentication/RegisterForm";

describe("Registration Form", () => {
  let confirmInput: HTMLElement;
  let emailInput: HTMLElement;
  let registerButton: HTMLElement;
  let passwordInput: HTMLElement;
  let usernameInput: HTMLElement;

  beforeEach(() => {
    render(<RegisterForm />);
    let confirmInputElement = screen.queryByLabelText("Confirm:");
    if (!confirmInputElement) {
      throw new Error("Confirm Input not found");
    }
    confirmInput = confirmInputElement;

    let emailInputElement = screen.queryByLabelText("Email:");
    if (!emailInputElement) {
      throw new Error("Email Input not found");
    }
    emailInput = emailInputElement;

    let registerButtonElement = screen.queryByRole("button", {
      name: "Register",
    });
    if (!registerButtonElement) {
      throw new Error("Register Button not found");
    }
    registerButton = registerButtonElement;

    let passwordInputElement = screen.queryByLabelText("Password:");
    if (!passwordInputElement) {
      throw new Error("Password Input not found");
    }
    passwordInput = passwordInputElement;

    let usernameInputElement = screen.queryByLabelText("Username:");
    if (!usernameInputElement) {
      throw new Error("Username Input not found");
    }
    usernameInput = usernameInputElement;
  });

  it("has form elements to register", () => {
    // Arrange

    // Act

    // Assert
    expect(confirmInput).toBeInTheDocument();
    expect(emailInput).toBeInTheDocument();
    expect(registerButton).toBeInTheDocument();
    expect(passwordInput).toBeInTheDocument();
    expect(usernameInput).toBeInTheDocument();
  });

  it("displays successful message", async () => {
    // Arrange
    const username = v4();
    const email = v4() + "@" + v4() + ".com";
    const password = v4();

    const mockApiCall = jest.fn().mockResolvedValue({
      data: {
        id: "1",
        jsonrpc: "2.0",
        result: {},
      },
    });

    axios.get = mockApiCall;

    // Act
    userEvent.type(usernameInput, username);
    userEvent.type(emailInput, email);
    userEvent.type(passwordInput, password);
    userEvent.type(confirmInput, password);
    userEvent.click(registerButton);

    // Assert
    const message = await screen.findByText("Successful registration!");
    expect(message).toBeInTheDocument();
  });
});
EOF
git add $FILE

npm test -- --watchAll=false && git commit --message="refactor - add more register fields" || exit 1
npx prettier --write .
git add --all
git commit --message "npx prettier --write ."

FILE=src/__test__/authentication/RegisterForm.test.tsx
cat > $FILE << EOF
import axios from "axios";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { v4 } from "uuid";
import RegisterForm from "../../authentication/RegisterForm";

describe("Registration Form", () => {
  let confirmInput: HTMLElement;
  let emailInput: HTMLElement;
  let registerButton: HTMLElement;
  let passwordInput: HTMLElement;
  let usernameInput: HTMLElement;

  beforeEach(() => {
    render(<RegisterForm />);

    let confirmInputElement = screen.queryByLabelText("Confirm:");
    if (!confirmInputElement) {
      throw new Error("Confirm Input not found");
    }
    confirmInput = confirmInputElement;

    let emailInputElement = screen.queryByLabelText("Email:");
    if (!emailInputElement) {
      throw new Error("Email Input not found");
    }
    emailInput = emailInputElement;

    let registerButtonElement = screen.queryByRole("button", {
      name: "Register",
    });
    if (!registerButtonElement) {
      throw new Error("Register Button not found");
    }
    registerButton = registerButtonElement;

    let passwordInputElement = screen.queryByLabelText("Password:");
    if (!passwordInputElement) {
      throw new Error("Password Input not found");
    }
    passwordInput = passwordInputElement;

    let usernameInputElement = screen.queryByLabelText("Username:");
    if (!usernameInputElement) {
      throw new Error("Username Input not found");
    }
    usernameInput = usernameInputElement;
  });

  it("has form elements to register", () => {
    // Arrange

    // Act

    // Assert
    expect(confirmInput).toBeInTheDocument();
    expect(emailInput).toBeInTheDocument();
    expect(registerButton).toBeInTheDocument();
    expect(passwordInput).toBeInTheDocument();
    expect(usernameInput).toBeInTheDocument();
  });

  it("displays successful message", async () => {
    // Arrange
    const username = v4();
    const email = v4() + "@" + v4() + ".com";
    const password = v4();
    const mockApiCall = jest.fn().mockResolvedValue({
      data: {
        id: "1",
        jsonrpc: "2.0",
        result: {},
      },
    });
    axios.get = mockApiCall;

    // Act
    userEvent.type(usernameInput, username);
    userEvent.type(emailInput, email);
    userEvent.type(passwordInput, password);
    userEvent.type(confirmInput, password);
    userEvent.click(registerButton);

    // Assert
    const message = await screen.findByText("Successful registration!");
    expect(message).toBeInTheDocument();
  });

  it("displays missing username message with no username", async () => {
    // Arrange

    // Act
    userEvent.click(registerButton);

    // Assert
    const usernameMissing = screen.getByText("Username is missing.");
    expect(usernameMissing).toBeInTheDocument();
    const errors = await screen.findByText("There were registration errors.");
    expect(errors).toBeInTheDocument();
  });

  it("displays missing username message with spaces", async () => {
    // Arrange
    userEvent.type(usernameInput, " ");

    // Act
    userEvent.click(registerButton);

    // Assert
    const usernameMissing = screen.getByText("Username is missing.");
    expect(usernameMissing).toBeInTheDocument();
    const errors = await screen.findByText("There were registration errors.");
    expect(errors).toBeInTheDocument();
  });

  it("displays missing email message with no email", async () => {
    // Arrange

    // Act
    userEvent.click(registerButton);

    // Assert
    const emailMissing = screen.getByText("Email is missing.");
    expect(emailMissing).toBeInTheDocument();
    const errors = await screen.findByText("There were registration errors.");
    expect(errors).toBeInTheDocument();
  });

  it("displays missing email message with spaces", async () => {
    // Arrange
    userEvent.type(emailInput, " ");

    // Act
    userEvent.click(registerButton);

    // Assert
    const emailMissing = screen.getByText("Email is missing.");
    expect(emailMissing).toBeInTheDocument();
    const errors = await screen.findByText("There were registration errors.");
    expect(errors).toBeInTheDocument();
  });

  it("displays missing password message with no password", async () => {
    // Arrange

    // Act
    userEvent.click(registerButton);

    // Assert
    const passwordMissing = screen.getByText("Password is missing.");
    expect(passwordMissing).toBeInTheDocument();
    const errors = await screen.findByText("There were registration errors.");
    expect(errors).toBeInTheDocument();
  });

  it("displays missing password message with spaces", async () => {
    // Arrange
    userEvent.type(passwordInput, " ");

    // Act
    userEvent.click(registerButton);

    // Assert
    const passwordMissing = screen.getByText("Password is missing.");
    expect(passwordMissing).toBeInTheDocument();
    const errors = await screen.findByText("There were registration errors.");
    expect(errors).toBeInTheDocument();
  });

  it("displays missing confirm message with no confirm", async () => {
    // Arrange

    // Act
    userEvent.click(registerButton);

    // Assert
    const confirmMissing = screen.getByText("Confirm is missing.");
    expect(confirmMissing).toBeInTheDocument();
    const errors = await screen.findByText("There were registration errors.");
    expect(errors).toBeInTheDocument();
  });

  it("displays missing confirm message with spaces", async () => {
    // Arrange
    userEvent.type(confirmInput, " ");

    // Act
    userEvent.click(registerButton);

    // Assert
    const confirmMissing = screen.getByText("Confirm is missing.");
    expect(confirmMissing).toBeInTheDocument();
    const errors = await screen.findByText("There were registration errors.");
    expect(errors).toBeInTheDocument();
  });

  it("displays not matching confirm message with not matching password", async () => {
    // Arrange
    userEvent.type(passwordInput, "abc");
    userEvent.type(confirmInput, "def");

    // Act
    userEvent.click(registerButton);

    // Assert
    const confirmMissing = screen.getByText("Confirm does not match password.");
    expect(confirmMissing).toBeInTheDocument();
    const errors = await screen.findByText("There were registration errors.");
    expect(errors).toBeInTheDocument();
  });
});
EOF
git add $FILE

npm test -- --watchAll=false && exit 1 || git commit --message="red - add more register errors"
npx prettier --write .
git add --all
git commit --message "npx prettier --write ."

FILE=src/authentication/RegisterForm.tsx
cat > $FILE << EOF
import axios from "axios";
import { useState } from "react";

export default function Register() {
  const [confirm, setConfirm] = useState("");
  const [confirmError, setConfirmError] = useState("");
  const [email, setEmail] = useState("");
  const [emailError, setEmailError] = useState("");
  const [errorMessage, setErrorMessage] = useState("");
  const [successMessage, setSuccessMessage] = useState("");
  const [password, setPassword] = useState("");
  const [passwordError, setPasswordError] = useState("");
  const [username, setUsername] = useState("");
  const [usernameError, setUsernameError] = useState("");

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

  const handleRegister = async (event: React.SyntheticEvent) => {
    event.preventDefault();
    let registrationError = false;
    let trimmedUsername = username.trim();
    if (!trimmedUsername) {
      setUsernameError("Username is missing.");
      registrationError = true;
    }
    let trimmedEmail = email.trim();
    if (!trimmedEmail) {
      setEmailError("Email is missing.");
      registrationError = true;
    }
    let trimmedPassword = password.trim();
    if (!trimmedPassword) {
      setPasswordError("Password is missing.");
      registrationError = true;
    }
    let trimmedConfirm = confirm.trim();
    if (!trimmedConfirm) {
      setConfirmError("Confirm is missing.");
      registrationError = true;
    } else if (trimmedPassword !== trimmedConfirm) {
      setConfirmError("Confirm does not match password.");
      registrationError = true;
    }
    if (registrationError) {
      setErrorMessage("There were registration errors.");
      return;
    }
    try {
      const response = await axios.get($SERVER_URL);
      if (response.data.result) {
        setSuccessMessage("Successful registration!");
      }
    } catch (error) {}
  };

  return (
    <form onSubmit={handleRegister}>
      <label htmlFor="username">
        Username:
        <input id="username" type="text" onChange={handleChangeUsername} />
      </label>
      {usernameError && <p>{usernameError}</p>}
      <label htmlFor="email">
        Email:
        <input id="email" type="email" onChange={handleChangeEmail} />
      </label>
      {emailError && <p>{emailError}</p>}
      <label htmlFor="password">
        Password:
        <input id="password" type="password" onChange={handleChangePassword} />
      </label>
      {passwordError && <p>{passwordError}</p>}
      <label htmlFor="confirm">
        Confirm:
        <input id="confirm" type="password" onChange={handleChangeConfirm} />
      </label>
      {confirmError && <p>{confirmError}</p>}
      <button data-test-id="register" type="submit">
        Register
      </button>
      {errorMessage && <p>{errorMessage}</p>}
      {successMessage && <p>{successMessage}</p>}
    </form>
  );
}
EOF
git add $FILE

npm test -- --watchAll=false && git commit --message="green - add more register errors" || exit 1
npx prettier --write .
git add --all
git commit --message "npx prettier --write ."

FILE=src/__test__/authentication/LoginForm.test.tsx
cat > $FILE << EOF
import axios from "axios";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { v4 } from "uuid";
import LoginForm from "../../authentication/LoginForm";

describe("Login Form", () => {
  let loginButton: HTMLElement;
  let passwordInput: HTMLElement;
  let usernameInput: HTMLElement;

  beforeEach(() => {
    render(<LoginForm />);

    let loginButtonElement = screen.queryByRole("button", {
      name: "Login",
    });
    if (!loginButtonElement) {
      throw new Error("Login Button not found");
    }
    loginButton = loginButtonElement;

    let passwordInputElement = screen.queryByLabelText("Password:");
    if (!passwordInputElement) {
      throw new Error("Password Input not found");
    }
    passwordInput = passwordInputElement;

    let usernameInputElement = screen.queryByLabelText("Username:");
    if (!usernameInputElement) {
      throw new Error("Username Input not found");
    }
    usernameInput = usernameInputElement;
  });

  it("has form elements to register", () => {
    // Arrange

    // Act

    // Assert
    expect(loginButton).toBeInTheDocument();
    expect(passwordInput).toBeInTheDocument();
    expect(usernameInput).toBeInTheDocument();
  });

  it("displays successful message", async () => {
    // Arrange
    const username = v4();
    const password = v4();
    const mockApiCall = jest.fn().mockResolvedValue({
      data: {
        id: "1",
        jsonrpc: "2.0",
        result: {},
      },
    });
    axios.get = mockApiCall;

    // Act
    userEvent.type(usernameInput, username);
    userEvent.type(passwordInput, password);
    userEvent.click(loginButton);

    // Assert
    const message = await screen.findByText("Successful login!");
    expect(message).toBeInTheDocument();
  });

  it("displays missing username message with no username", async () => {
    // Arrange

    // Act
    userEvent.click(loginButton);

    // Assert
    const usernameMissing = screen.getByText("Username is missing.");
    expect(usernameMissing).toBeInTheDocument();
    const errors = await screen.findByText("There were login errors.");
    expect(errors).toBeInTheDocument();
  });

  it("displays missing username message with spaces", async () => {
    // Arrange
    userEvent.type(usernameInput, " ");

    // Act
    userEvent.click(loginButton);

    // Assert
    const usernameMissing = screen.getByText("Username is missing.");
    expect(usernameMissing).toBeInTheDocument();
    const errors = await screen.findByText("There were login errors.");
    expect(errors).toBeInTheDocument();
  });

  it("displays missing password message with no password", async () => {
    // Arrange

    // Act
    userEvent.click(loginButton);

    // Assert
    const passwordMissing = screen.getByText("Password is missing.");
    expect(passwordMissing).toBeInTheDocument();
    const errors = await screen.findByText("There were login errors.");
    expect(errors).toBeInTheDocument();
  });

  it("displays missing password message with spaces", async () => {
    // Arrange
    userEvent.type(passwordInput, " ");

    // Act
    userEvent.click(loginButton);

    // Assert
    const passwordMissing = screen.getByText("Password is missing.");
    expect(passwordMissing).toBeInTheDocument();
    const errors = await screen.findByText("There were login errors.");
    expect(errors).toBeInTheDocument();
  });
});
EOF
git add $FILE

npm test -- --watchAll=false && exit 1 || git commit --message="red - added login form"
npx prettier --write .
git add --all
git commit --message "npx prettier --write ."

FILE=src/authentication/LoginForm.tsx
cat > $FILE << EOF
import axios from "axios";
import { useState } from "react";

export default function LoginForm() {
  const [errorMessage, setErrorMessage] = useState("");
  const [successMessage, setSuccessMessage] = useState("");
  const [password, setPassword] = useState("");
  const [passwordError, setPasswordError] = useState("");
  const [username, setUsername] = useState("");
  const [usernameError, setUsernameError] = useState("");

  const handleChangePassword = (event: React.ChangeEvent<HTMLInputElement>) => {
    setPassword(event.target.value);
  };

  const handleChangeUsername = (event: React.ChangeEvent<HTMLInputElement>) => {
    setUsername(event.target.value);
  };

  const handleRegister = async (event: React.SyntheticEvent) => {
    event.preventDefault();
    let loginError = false;
    let trimmedUsername = username.trim();
    if (!trimmedUsername) {
      setUsernameError("Username is missing.");
      loginError = true;
    }
    let trimmedPassword = password.trim();
    if (!trimmedPassword) {
      setPasswordError("Password is missing.");
      loginError = true;
    }
    if (loginError) {
      setErrorMessage("There were login errors.");
      return;
    }
    try {
      const response = await axios.get($SERVER_URL);
      if (response.data.result) {
        setSuccessMessage("Successful login!");
      }
    } catch (error) {}
  };

  return (
    <form onSubmit={handleRegister}>
      <label htmlFor="username">
        Username:
        <input id="username" type="text" onChange={handleChangeUsername} />
      </label>
      {usernameError && <p>{usernameError}</p>}
      <label htmlFor="password">
        Password:
        <input id="password" type="password" onChange={handleChangePassword} />
      </label>
      {passwordError && <p>{passwordError}</p>}
      <button data-test-id="login" type="submit">
        Login
      </button>
      {errorMessage && <p>{errorMessage}</p>}
      {successMessage && <p>{successMessage}</p>}
    </form>
  );
}
EOF
git add $FILE

npm test -- --watchAll=false && git commit --message="green - added login form" || exit 1
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

FILE=cypress/e2e/$SNAKE.cy.ts
cat > $FILE << EOF
describe("$CANONICAL app", () => {
  it("passes", () => {
    cy.visit("$CLIENT_URL");
    cy.contains("$CANONICAL");
  });
});
EOF
git add $FILE

npx cypress run && exit 1 || git commit --message="red - display application name"
npx prettier --write .
git add --all
git commit --message "npx prettier --write ."

FILE=src/App.tsx
cat > $FILE << EOF
import React from "react";

function App() {
  return <h1>$CANONICAL</h1>;
}

export default App;
EOF
git add $FILE

npx cypress run && git commit --message="green - display application name" || exit 1
npx prettier --write .
git add --all
git commit --message "npx prettier --write ."

git push --force

cd ..

killall -15 node
