#!/usr/bin/env bash

SCRIPT=$0
FRAMEWORK=$1
REPOSITORY=$2
SERVER=$3
TEMPLATE=$4

echo " - Running $SCRIPT $FRAMEWORK $REPOSITORY $SERVER $TEMPLATE"

if [ $# -ne 4 ]; then
  echo "usage: $SCRIPT <REPOSITORY> <SERVER>"
  exit 1
fi

pushd .

NAME=client-web

# global - checkout first commit
./intrepion-apps/new/common/checkout_first_commit.sh $REPOSITORY

# framework - add template files
./intrepion-apps/new/common/framework/$FRAMEWORK/add_template_files.sh $REPOSITORY $TEMPLATE

# template - remove boilerplate
./intrepion-apps/new/common/framework/$FRAMEWORK/$TEMPLATE/remove_boilerplate.sh $REPOSITORY

# template - add health check
./intrepion-apps/new/common/framework/$FRAMEWORK/$TEMPLATE/add_health_check.sh $REPOSITORY

# type - add user routes
./intrepion-apps/new/common/type/full_stack/$FRAMEWORK/add_user_routes.sh $REPOSITORY

# type - add local commands
./intrepion-apps/new/common/type/full_stack/$FRAMEWORK/add_local_commands.sh $REPOSITORY $SERVER

# framework - add digital ocean files
./intrepion-apps/new/common/framework/$FRAMEWORK/add_digital_ocean_files.sh $NAME $REPOSITORY

popd

echo " - Completed $SCRIPT $FRAMEWORK $REPOSITORY $SERVER $TEMPLATE"
