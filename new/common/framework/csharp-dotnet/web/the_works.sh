#!/usr/bin/env bash

SCRIPT=$0
FRAMEWORK=$1
PASCAL=$2
PROJECT=$3
REPOSITORY=$4
TEMPLATE=$5
USER=$6

echo "Running $SCRIPT $FRAMEWORK $PASCAL $PROJECT $REPOSITORY $TEMPLATE $USER"

pushd .

# global - checkout first commit
./$USER-apps/new/common/checkout_first_commit.sh $REPOSITORY $USER

# framework - add template files
./$USER-apps/new/common/framework/$FRAMEWORK/add_template_files.sh $PASCAL $PROJECT $REPOSITORY $TEMPLATE

# framework - add local commands
./$USER-apps/new/common/framework/$FRAMEWORK/add_local_commands.sh $PROJECT $REPOSITORY

# framework - add deployment files
./$USER-apps/new/common/framework/$FRAMEWORK/add_deployment_files.sh $PASCAL $PROJECT $REPOSITORY $USER

# template - remove boilerplate
./$USER-apps/new/common/framework/$FRAMEWORK/$TEMPLATE/remove_boilerplate.sh

# template - add health check
./$USER-apps/new/common/framework/$FRAMEWORK/$TEMPLATE/add_health_check.sh $PROJECT $REPOSITORY

popd

echo "Completed $SCRIPT $FRAMEWORK $PASCAL $PROJECT $REPOSITORY $TEMPLATE $USER"
