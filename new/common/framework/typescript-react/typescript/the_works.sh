#!/usr/bin/env bash

SCRIPT=$0
FRAMEWORK=$1
REPOSITORY=$2
TEMPLATE=$3
USER=$4

echo "Running $SCRIPT $FRAMEWORK $REPOSITORY $TEMPLATE $USER"

pushd .

# global - checkout first commit
./$USER-apps/new/common/checkout_first_commit.sh $REPOSITORY $USER

# framework - add template files
./$USER-apps/new/common/framework/$FRAMEWORK/add_template_files.sh $REPOSITORY $TEMPLATE

# framework - add local commands
./$USER-apps/new/common/framework/$FRAMEWORK/add_local_commands.sh $REPOSITORY

# framework - add deployment files
./$USER-apps/new/common/framework/$FRAMEWORK/add_deployment_files.sh $REPOSITORY $USER

# template - remove boilerplate
./$USER-apps/new/common/framework/$FRAMEWORK/$TEMPLATE/remove_boilerplate.sh $REPOSITORY

# template - add health check
./$USER-apps/new/common/framework/$FRAMEWORK/$TEMPLATE/add_health_check.sh $REPOSITORY

popd

echo "Completed $SCRIPT $FRAMEWORK $REPOSITORY $TEMPLATE $USER"
