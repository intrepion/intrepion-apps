#!/usr/bin/env bash

SCRIPT=$0
FRAMEWORK=$1
PASCAL=$2
PROJECT=$3
REPOSITORY=$4
TEMPLATE=$5

echo " - Running $SCRIPT $FRAMEWORK $PASCAL $PROJECT $REPOSITORY $TEMPLATE"

if [ $# -ne 5 ]; then
  echo "usage: $SCRIPT <FRAMEWORK> <PASCAL> <PROJECT> <REPOSITORY> <TEMPLATE>"
  exit 1
fi

pushd .

NAME=web

# global - checkout first commit
./intrepion-apps/new/common/checkout_first_commit.sh $REPOSITORY

# framework - add template files
./intrepion-apps/new/common/framework/$FRAMEWORK/add_template_files.sh $PASCAL $PROJECT $REPOSITORY $TEMPLATE

# template - remove boilerplate
./intrepion-apps/new/common/framework/$FRAMEWORK/$TEMPLATE/remove_boilerplate.sh $PASCAL $REPOSITORY

# template - add health check
./intrepion-apps/new/common/framework/$FRAMEWORK/$TEMPLATE/add_health_check.sh $PASCAL $REPOSITORY

# framework - add local commands
./intrepion-apps/new/common/framework/$FRAMEWORK/add_local_commands.sh $PROJECT $REPOSITORY

# framework - add github actions
./intrepion-apps/new/common/framework/$FRAMEWORK/add_github_actions.sh $REPOSITORY

# framework - add digital ocean files
./intrepion-apps/new/common/framework/$FRAMEWORK/add_digital_ocean_files.sh $KEBOB $NAME $PASCAL $PROJECT $REPOSITORY

popd

echo " - Completed $SCRIPT $FRAMEWORK $PASCAL $PROJECT $REPOSITORY $TEMPLATE"
