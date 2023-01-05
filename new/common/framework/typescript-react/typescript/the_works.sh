#!/usr/bin/env bash

SCRIPT=$0
FRAMEWORK=$1
REPOSITORY=$2
TEMPLATE=$3

echo " - Running $SCRIPT $FRAMEWORK $REPOSITORY $TEMPLATE"

if [ $# -ne 3 ]; then
  echo "usage: $SCRIPT <FRAMEWORK> <REPOSITORY> <TEMPLATE>"
  exit 1
fi

pushd .

NAME=web

# global - checkout first commit
./intrepion-apps/new/common/checkout_first_commit.sh $REPOSITORY

# framework - add template files
./intrepion-apps/new/common/framework/$FRAMEWORK/add_template_files.sh $REPOSITORY $TEMPLATE

# template - remove boilerplate
./intrepion-apps/new/common/framework/$FRAMEWORK/$TEMPLATE/remove_boilerplate.sh $REPOSITORY

# framework - add local commands
./intrepion-apps/new/common/framework/$FRAMEWORK/add_local_commands.sh $REPOSITORY

# framework - add digital ocean files
./intrepion-apps/new/common/framework/$FRAMEWORK/add_digital_ocean_files.sh $NAME $REPOSITORY

popd

echo " - Completed $SCRIPT $FRAMEWORK $REPOSITORY $TEMPLATE"
