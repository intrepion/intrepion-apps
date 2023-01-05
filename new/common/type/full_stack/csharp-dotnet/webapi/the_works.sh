#!/usr/bin/env bash

SCRIPT=$0
CLIENT=$1
FRAMEWORK=$2
KEBOB=$3
PASCAL=$4
PROJECT=$5
REPOSITORY=$6
TEMPLATE=$7

echo " - Running $SCRIPT $CLIENT $FRAMEWORK $KEBOB $PASCAL $PROJECT $REPOSITORY $TEMPLATE"

if [ $# -ne 7 ]; then
  echo "usage: $SCRIPT <CLIENT> <FRAMEWORK> <KEBOB> <PASCAL> <PROJECT> <REPOSITORY> <TEMPLATE>"
  exit 1
fi

pushd .

NAME=server

# global - checkout first commit
./intrepion-apps/new/common/checkout_first_commit.sh $REPOSITORY

# type - add template files
./intrepion-apps/new/common/type/full_stack/$FRAMEWORK/add_template_files.sh $PASCAL $PROJECT $REPOSITORY $TEMPLATE

# template - remove boilerplate
./intrepion-apps/new/common/framework/$FRAMEWORK/$TEMPLATE/remove_boilerplate.sh $PASCAL $REPOSITORY

# template - add health check
./intrepion-apps/new/common/framework/$FRAMEWORK/$TEMPLATE/add_health_check.sh $PASCAL $REPOSITORY

# type - add postgres
./intrepion-apps/new/common/type/full_stack/$FRAMEWORK/add_postgres.sh $KEBOB $PASCAL $PROJECT $REPOSITORY $TEMPLATE

# type - add json-rpc files
./intrepion-apps/new/common/type/full_stack/$FRAMEWORK/add_json_rpc_files.sh $PASCAL $REPOSITORY

# type - add local commands
./intrepion-apps/new/common/type/full_stack/$FRAMEWORK/add_local_commands.sh $CLIENT $PROJECT $REPOSITORY

# type - add github actions
./intrepion-apps/new/common/type/full_stack/$FRAMEWORK/add_github_actions.sh $KEBOB $REPOSITORY

# framework - add digital ocean files
./intrepion-apps/new/common/framework/$FRAMEWORK/add_digital_ocean_files.sh $KEBOB $NAME $PASCAL $PROJECT $REPOSITORY
popd

echo " - Completed $SCRIPT $CLIENT $FRAMEWORK $KEBOB $PASCAL $PROJECT $REPOSITORY $TEMPLATE"
