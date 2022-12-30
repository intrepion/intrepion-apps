#!/bin/bash

SCRIPT=$0
PASCAL=$1
PROJECT=$2
REPOSITORY=$3
TEMPLATE=$4

echo "Running $SCRIPT $PASCAL $PROJECT $REPOSITORY $TEMPLATE"

pushd .

cd $REPOSITORY

# Create a gitignore file
dotnet new gitignore
git add .gitignore
git commit --message "dotnet new gitignore"

# Create a solution with the application name appended with "App"
dotnet new sln --name ${PASCAL}App
git add ${PASCAL}App.sln
git commit --message "dotnet new sln --name ${PASCAL}App"

# Create a library project with the application name appended with "Library"
dotnet new classlib --name ${PASCAL}Library
git add ${PASCAL}Library
git commit --message "dotnet new classlib --name ${PASCAL}Library"

# Add the library project to the solution
dotnet sln ${PASCAL}App.sln add ${PASCAL}Library
git add ${PASCAL}App.sln
git commit --message "dotnet sln ${PASCAL}App.sln add ${PASCAL}Library"

# Create a template project with the application name
dotnet new $TEMPLATE --name $PROJECT
git add $PROJECT
git commit --message "dotnet new $TEMPLATE --name $PROJECT"

# Add the template project to the solution
dotnet sln ${PASCAL}App.sln add $PROJECT
git add ${PASCAL}App.sln
git commit --message "dotnet sln ${PASCAL}App.sln add $PROJECT"

# Add a reference to the library project in the template project
dotnet add $PROJECT reference ${PASCAL}Library
git add $PROJECT
git commit --message "dotnet add $PROJECT reference ${PASCAL}Library"

# Create a xunit project with the application name appended with "Tests"
dotnet new xunit --name ${PASCAL}Tests
git add ${PASCAL}Tests
git commit --message "dotnet new xunit --name ${PASCAL}Tests"

cd ${PASCAL}Tests && dotnet add package Microsoft.AspNetCore.Mvc.Testing
cd ..
git add ${PASCAL}Tests
git commit --message "cd ${PASCAL}Tests && dotnet add package Microsoft.AspNetCore.Mvc.Testing"

# Add the xunit project to the solution
dotnet sln ${PASCAL}App.sln add ${PASCAL}Tests
git add ${PASCAL}App.sln
git commit --message "dotnet sln ${PASCAL}App.sln add ${PASCAL}Tests"

# Add a reference to the library project in the test project
dotnet add ${PASCAL}Tests reference ${PASCAL}Library
git add ${PASCAL}Tests
git commit --message "dotnet add ${PASCAL}Tests reference ${PASCAL}Library"

# Add a reference to the template project in the test project
dotnet add ${PASCAL}Tests reference $PROJECT
git add ${PASCAL}Tests
git commit --message "dotnet add ${PASCAL}Tests reference $PROJECT"

popd

echo "Completed $SCRIPT $PASCAL $PROJECT $REPOSITORY $TEMPLATE"
