#!/bin/bash

SCRIPT=$0
PASCAL=$1
PROJECT=$2
REPOSITORY=$3
TEMPLATE=$4

echo " - Running $SCRIPT $PASCAL $PROJECT $REPOSITORY $TEMPLATE"

if [ $# -ne 4 ]; then
  echo "usage: $SCRIPT <PASCAL> <PROJECT> <REPOSITORY> <TEMPLATE>"
  exit 1
fi

pushd .

cd $REPOSITORY
pwd

dotnet new gitignore
git add .gitignore
git commit --message "dotnet new gitignore"

dotnet new sln --name ${PASCAL}App
git add ${PASCAL}App.sln
git commit --message "dotnet new sln --name ${PASCAL}App"

dotnet new classlib --name ${PASCAL}Library
git add ${PASCAL}Library
git commit --message "dotnet new classlib --name ${PASCAL}Library"

dotnet sln ${PASCAL}App.sln add ${PASCAL}Library
git add ${PASCAL}App.sln
git commit --message "dotnet sln ${PASCAL}App.sln add ${PASCAL}Library"

dotnet new classlib --name Intrepion.JsonRpc
git add Intrepion.JsonRpc
git commit --message "dotnet new classlib --name Intrepion.JsonRpc"

dotnet sln ${PASCAL}App.sln add Intrepion.JsonRpc
git add ${PASCAL}App.sln
git commit --message "dotnet sln ${PASCAL}App.sln add Intrepion.JsonRpc"

dotnet new $TEMPLATE --name $PROJECT
git add $PROJECT
git commit --message "dotnet new $TEMPLATE --auth Individual --name $PROJECT --use-local-db"

dotnet sln ${PASCAL}App.sln add $PROJECT
git add ${PASCAL}App.sln
git commit --message "dotnet sln ${PASCAL}App.sln add $PROJECT"

dotnet add $PROJECT reference ${PASCAL}Library
git add $PROJECT
git commit --message "dotnet add $PROJECT reference ${PASCAL}Library"

dotnet add $PROJECT reference Intrepion.JsonRpc
git add $PROJECT
git commit --message "dotnet add $PROJECT reference Intrepion.JsonRpc"

dotnet add $PROJECT package Microsoft.AspNetCore.Cors
git add $PROJECT
git commit --message "dotnet add $PROJECT package Microsoft.AspNetCore.Cors"

dotnet add $PROJECT package Microsoft.AspNetCore.Identity.EntityFrameworkCore
git add $PROJECT
git commit --message "dotnet add $PROJECT package Microsoft.AspNetCore.Identity.EntityFrameworkCore"

dotnet add $PROJECT package Microsoft.AspNetCore.Authentication.JwtBearer
git add $PROJECT
git commit --message "dotnet add $PROJECT package Microsoft.AspNetCore.Authentication.JwtBearer"

dotnet new xunit --name ${PASCAL}Tests
git add ${PASCAL}Tests
git commit --message "dotnet new xunit --name ${PASCAL}Tests"

dotnet add ${PASCAL}Tests package Microsoft.AspNetCore.Mvc.Testing
git add ${PASCAL}Tests
git commit --message "dotnet add ${PASCAL}Tests package Microsoft.AspNetCore.Mvc.Testing"

dotnet sln ${PASCAL}App.sln add ${PASCAL}Tests
git add ${PASCAL}App.sln
git commit --message "dotnet sln ${PASCAL}App.sln add ${PASCAL}Tests"

dotnet add ${PASCAL}Tests reference ${PASCAL}Library
git add ${PASCAL}Tests
git commit --message "dotnet add ${PASCAL}Tests reference ${PASCAL}Library"

dotnet add ${PASCAL}Tests reference Intrepion.JsonRpc
git add ${PASCAL}Tests
git commit --message "dotnet add ${PASCAL}Tests reference Intrepion.JsonRpc"

dotnet add ${PASCAL}Tests reference $PROJECT
git add ${PASCAL}Tests
git commit --message "dotnet add ${PASCAL}Tests reference $PROJECT"

popd

echo " - Completed $SCRIPT $PASCAL $PROJECT $REPOSITORY $TEMPLATE"
