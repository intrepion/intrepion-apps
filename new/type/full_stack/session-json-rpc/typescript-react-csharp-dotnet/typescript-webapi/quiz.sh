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
dotnet test && exit 1 || git commit --message="red - testing the health check controller for 200 status"

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
dotnet test && git commit --message="green - testing the health check controller for 200 status" || exit 1

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
dotnet test && exit 1 || git commit --message="red - trying to use the get endpoint"

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
dotnet test && git commit --message="green - trying to use the get endpoint" || exit 1

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
        actualResult.Should().BeOfType<OkObjectResult>();
        var okObjectResult = (OkObjectResult)actualResult;
        okObjectResult.StatusCode.Should().Be(200);
    }
}
EOF
git add $FILE

dotnet test && git commit --message="refactor - using fluent assertions to check the status code" || exit 1

# git push --force

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

cd $CLIENT_REPOSITORY
pwd

npx create-react-app . --template $CLIENT_TEMPLATE
git add --all
git commit --message "npx create-react-app . --template $CLIENT_TEMPLATE"

mv README.old.md README.md
git add README.old.md README.md
git commit --message "mv README.old.md README.md"

npm install --save-dev --save-exact prettier
git add --all
git commit --message "npm install --save-dev --save-exact prettier"

echo {}> .prettierrc.json
git add .prettierrc.json
git commit --message "echo {}> .prettierrc.json"

cp .gitignore .prettierignore
git add .prettierignore
git commit --message "cp .gitignore .prettierignore"

npx prettier --write .
git add --all
git commit --message "npx prettier --write ."

npm install uuid
git add --all
git commit --message "npm install uuid"

npm i --save-dev @types/uuid
git add --all
git commit --message "npm install --save-dev @types/uuid"

# npm install --save-dev @testing-library/react
# git add --all
# git commit --message "npm install --save-dev @testing-library/react"

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

FILE=src/__test__/Login.test.tsx
cat > $FILE << EOF
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import "@testing-library/jest-dom";
import Login from "../Login";

test("allows the user to login successfully", async () => {
  // mock out window.fetch for the test
  const fakeUserResponse = { token: "fake_user_token" };
  jest.spyOn(window, "fetch").mockImplementationOnce(() => {
    return Promise.resolve({
      json: () => Promise.resolve(fakeUserResponse),
    });
  });

  render(<Login />);

  // fill out the form
  userEvent.type(screen.getByLabelText(/username/i), "chuck");
  userEvent.type(screen.getByLabelText(/password/i), "norris");

  userEvent.click(screen.getByText(/submit/i));

  // just like a manual tester, we'll instruct our test to wait for the alert
  // to show up before continuing with our assertions.
  const alert = await screen.findByRole("alert");

  // .toHaveTextContent() comes from jest-dom's assertions
  // otherwise you could use expect(alert.textContent).toMatch(/congrats/i)
  // but jest-dom will give you better error messages which is why it's recommended
  expect(alert).toHaveTextContent(/congrats/i);
  expect(window.localStorage.getItem("token")).toEqual(fakeUserResponse.token);
});
EOF
git add $FILE

npm test -- --watchAll=false && exit 1 || git commit --message="red - add login"

FILE=src/Login.tsx
cat > $FILE << EOF
import * as React from "react";

function Login() {
  const [state, setState] = React.useReducer((s, a) => ({ ...s, ...a }), {
    resolved: false,
    loading: false,
    error: null,
  });

  function handleSubmit(event) {
    event.preventDefault();
    const { usernameInput, passwordInput } = event.target.elements;

    setState({ loading: true, resolved: false, error: null });

    window
      .fetch("/api/login", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          username: usernameInput.value,
          password: passwordInput.value,
        }),
      })
      .then((r) => r.json())
      .then(
        (user) => {
          setState({ loading: false, resolved: true, error: null });
          window.localStorage.setItem("token", user.token);
        },
        (error) => {
          setState({ loading: false, resolved: false, error: error.message });
        }
      );
  }

  return (
    <div>
      <form onSubmit={handleSubmit}>
        <div>
          <label htmlFor="usernameInput">Username</label>
          <input id="usernameInput" />
        </div>
        <div>
          <label htmlFor="passwordInput">Password</label>
          <input id="passwordInput" type="password" />
        </div>
        <button type="submit">Submit{state.loading ? "..." : null}</button>
      </form>
      {state.error ? <div role="alert">{state.error.message}</div> : null}
      {state.resolved ? (
        <div role="alert">Congrats! You're signed in!</div>
      ) : null}
    </div>
  );
}

export default Login;
EOF
git add $FILE

npm test -- --watchAll=false && git commit --message="green - add login" || exit 1

# git push --force

cd ..
