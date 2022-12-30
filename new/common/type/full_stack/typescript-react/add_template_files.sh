#!/bin/bash

SCRIPT=$0
REPOSITORY=$1
TEMPLATE=$2

echo "Running $SCRIPT $REPOSITORY $TEMPLATE"

pushd .

cd $REPOSITORY

# Create a template project with the repository name
npx create-react-app . --template $TEMPLATE
git add --all
git commit --message "npx create-react-app . --template $TEMPLATE"

# Restore the old README file
mv README.old.md README.md
git add README.old.md README.md
git commit --message "mv README.old.md README.md"

# Install prettier
npm install --save-dev --save-exact prettier
git add --all
git commit --message "npm install --save-dev --save-exact prettier"

# Create an empty prettier configuration file
echo {}> .prettierrc.json
git add .prettierrc.json
git commit --message "echo {}> .prettierrc.json"

# Create a prettier ignore file based on the gitignore file
cp .gitignore .prettierignore
git add .prettierignore
git commit --message "cp .gitignore .prettierignore"

# Run prettier
npx prettier --write .
git add --all
git commit --message "npx prettier --write ."

popd

echo "Completed $SCRIPT $REPOSITORY $TEMPLATE"
