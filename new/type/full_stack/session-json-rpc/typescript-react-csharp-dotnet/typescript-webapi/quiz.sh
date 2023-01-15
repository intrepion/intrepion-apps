#!/usr/bin/env bash

SCRIPT=$0

echo " - Running $SCRIPT"

pushd .

cd ..
pwd

CANONICAL="Quiz"
CLIENT_URL="http://localhost:3000"
CLIENT_FRAMEWORK=typescript-react
CLIENT_TEMPLATE=typescript
CONTRACT=session-json-rpc
KEBOB=quiz
PASCAL=Quiz
SERVER_FRAMEWORK=csharp-dotnet
SERVER_TEMPLATE=webapi
SNAKE=quiz

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

FOLDER=$PROJECT/Controllers
rm -rf $FOLDER
git add $FOLDER

FILE=$PROJECT/WeatherForecast.cs
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
name: .NET

on:
  push:
    branches: ["main"]
  pull_request:
    branches: ["main"]

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

[![.NET](https://github.com/intrepion/$SERVER_REPOSITORY/actions/workflows/dotnet.yml/badge.svg?branch=main)](https://github.com/intrepion/$SERVER_REPOSITORY/actions/workflows/dotnet.yml)
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
namespace $SOLUTION.Tests.WebApi.HealthCheck;

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
dotnet test && exit 1 || git commit --message="red - testing the health check controller for 200 status"

mkdir -p $PROJECT/HealthCheck

FILE=$PROJECT/HealthCheck/HealthCheckController.cs
cat > $FILE << EOF
namespace $PROJECT.HealthCheck;

public class HealthCheckController {}
EOF
git add $FILE

FILE=$SOLUTION.Tests/WebApi/HealthCheck/TestHealthCheckController.cs
cat > $FILE << EOF
using $PROJECT.HealthCheck;

namespace $SOLUTION.Tests.WebApi.HealthCheck;

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
dotnet test && git commit --message="green - testing the health check controller for 200 status" || exit 1

FILE=$SOLUTION.Tests/WebApi/HealthCheck/TestHealthCheckController.cs
cat > $FILE << EOF
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
    }
}
EOF
git add $FILE
dotnet test && exit 1 || git commit --message="red - trying to use the get endpoint"

FILE=$PROJECT/HealthCheck/HealthCheckController.cs
cat > $FILE << EOF
namespace $PROJECT.HealthCheck;

public class HealthCheckController
{
    public string Get()
    {
        return "";
    }
}
EOF
git add $FILE
dotnet test && git commit --message="green - trying to use the get endpoint" || exit 1

FILE=$SOLUTION.Tests/WebApi/HealthCheck/TestHealthCheckController.cs
cat > $FILE << EOF
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
    }
}
EOF
git add $FILE
dotnet test && exit 1 || git commit --message="red - using fluent assertions to check the status code"

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
    }
}
EOF
git add $FILE

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
dotnet test && git commit --message="green - using fluent assertions to check the status code" || exit 1

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
dotnet test && git commit --message="refactor - using fluent assertions to check the status code" || exit 1

mkdir -p $SOLUTION.Tests/Endpoints

FILE=$SOLUTION.Tests/Endpoints/TestHealthCheckEndpoint.cs
cat > $FILE << EOF
using Microsoft.AspNetCore.Mvc.Testing;

namespace QuizApp.Tests.WebApi.HealthCheck;

public class TestHealthCheckEndpoint : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> _factory;

    public TestHealthCheckEndpoint(WebApplicationFactory<Program> factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task Get_EndpointsReturnSuccessAndCorrectContentType()
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

public partial class Program {}
EOF
git add $FILE

FILE=$PROJECT/HealthCheck/HealthCheckController.cs
cat > $FILE << EOF
using Microsoft.AspNetCore.Mvc;

namespace QuizApp.WebApi.HealthCheck;

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

git push --force

FILE=$PROJECT/Properties/launchSettings.json
SERVER_URL=$(jq '.profiles.http.applicationUrl' $FILE)

cd ..

if [ ! -d "$CLIENT_REPOSITORY" ]; then
  git clone git@github.com:intrepion/$CLIENT_REPOSITORY.git
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

mkdir -p .github/workflows

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

mkdir -p .do

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

mkdir -p scripts

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

mkdir -p cypress/support

FILE=cypress/support/e2e.ts
touch $FILE
git add $FILE

git commit --message="Added cypress files."
npx prettier --write .
git add --all
git commit --message "npx prettier --write ."

mkdir -p cypress/e2e

FILE=cypress/e2e/$SNAKE.cy.ts
cat > $FILE << EOF
describe("$CANONICAL app", () => {
  it("passes", () => {
    cy.visit("http://localhost:3000");
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

mkdir -p src/__test__/authentication

FILE=src/__test__/authentication/RegisterForm.test.tsx
cat > $FILE << EOF
import { render, screen } from "@testing-library/react";
import RegisterForm from "../../authentication/RegisterForm";

describe("Registration", () => {
  it("has button to register", () => {
    render(<RegisterForm />);
    const registerButton = screen.queryByRole("button", {
      name: "Register",
    });
    expect(registerButton).toBeInTheDocument();
  });
});
EOF
git add $FILE

npm test -- --watchAll=false && exit 1 || git commit --message="red - add register form button"
npx prettier --write .
git add --all
git commit --message "npx prettier --write ."

mkdir -p src/authentication

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

describe("Registration", () => {
  it("has button to register", () => {
    render(<RegisterForm />);
    const registerButton = screen.queryByRole("button", {
      name: "Register",
    });
    expect(registerButton).toBeInTheDocument();
  });

  it("displays successful message", async () => {
    render(<RegisterForm />);
    const registerButton = screen.queryByRole("button", {
      name: "Register",
    });

    if (!registerButton) {
      throw new Error("Button not found");
    }

    const mockApiCall = jest.fn().mockResolvedValue({
      data: {
        id: "1",
        jsonrpc: "2.0",
        result: {},
      },
    });

    axios.get = mockApiCall;

    userEvent.click(registerButton);

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

mkdir -p src/authentication

FILE=src/authentication/RegisterForm.tsx
cat > $FILE << EOF
import axios from "axios";
import { useState } from "react";

export default function Register() {
  const [successMessage, setSuccessMessage] = useState("");

  const handleRegister = async () => {
    try {
      const response = await axios.get("http://localhost:5046");
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

git push --force

cd ..
