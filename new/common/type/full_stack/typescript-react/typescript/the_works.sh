#!/usr/bin/env bash

SCRIPT=$0
FRAMEWORK=$1
REPOSITORY=$2
TEMPLATE=$3

echo "Running $SCRIPT $FRAMEWORK $REPOSITORY $TEMPLATE"

pushd .

# global - checkout first commit
./intrepion-apps/new/common/checkout_first_commit.sh $REPOSITORY

# type - add template files
./intrepion-apps/new/common/type/full_stack/$FRAMEWORK/add_template_files.sh $REPOSITORY $TEMPLATE

# framework - add local commands
./intrepion-apps/new/common/framework/$FRAMEWORK/add_local_commands.sh $REPOSITORY

# framework - add digital ocean files
./intrepion-apps/new/common/framework/$FRAMEWORK/add_digital_ocean_files.sh $NAME $REPOSITORY

# template - remove boilerplate
./intrepion-apps/new/common/framework/$FRAMEWORK/$TEMPLATE/remove_boilerplate.sh $REPOSITORY

# template - add health check
./intrepion-apps/new/common/framework/$FRAMEWORK/$TEMPLATE/add_health_check.sh $REPOSITORY

popd

echo "Completed $SCRIPT $FRAMEWORK $REPOSITORY $TEMPLATE"
