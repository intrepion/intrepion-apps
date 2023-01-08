#!/bin/bash

SCRIPT=$0
REPOSITORY=$1
TEMPLATE=$2

echo " - Running $SCRIPT $REPOSITORY $TEMPLATE"

if [ $# -ne 2 ]; then
  echo "usage: $SCRIPT <REPOSITORY> <TEMPLATE>"
  exit 1
fi

pushd .

cd $REPOSITORY
pwd

npx create-react-app . --template $TEMPLATE
git add --all
git commit --message "npx create-react-app . --template $TEMPLATE"

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
git commit --message "npm i --save-dev @types/uuid"

npm install axios
git add --all
git commit --message "npm install axios"

npx prettier --write .
git add --all
git commit --message "npx prettier --write ."

popd

echo " - Completed $SCRIPT $REPOSITORY $TEMPLATE"
