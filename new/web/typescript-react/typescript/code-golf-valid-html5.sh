#!/usr/bin/env bash

SCRIPT=$0

echo "Running $SCRIPT"

pushd .

cd ..

FRAMEWORK=typescript-react
KEBOB=code-golf-valid-html5
TEMPLATE=typescript
TYPE=web
USER=intrepion

REPOSITORY=$USER-$KEBOB-$TYPE-$FRAMEWORK-$TEMPLATE

# global - checkout first commit
./$USER-apps/new/common/checkout_first_commit.sh $REPOSITORY $USER

# framework - add template files
./$USER-apps/new/$TYPE/$FRAMEWORK/common/add_template_files.sh $REPOSITORY $TEMPLATE

# framework - add local commands
./$USER-apps/new/$TYPE/$FRAMEWORK/common/add_local_commands.sh $REPOSITORY

# framework - add deployment files
./$USER-apps/new/$TYPE/$FRAMEWORK/common/add_deployment_files.sh $REPOSITORY $USER

# template - remove boilerplate
./$USER-apps/new/$TYPE/$FRAMEWORK/$TEMPLATE/common/remove_boilerplate.sh $REPOSITORY

# template - add health check
./$USER-apps/new/$TYPE/$FRAMEWORK/$TEMPLATE/common/add_health_check.sh $REPOSITORY

# project - add minimal html5 to pass validation
cd $REPOSITORY

git push --force

cd ..

# framework - add run scripts
./$USER-apps/new/$TYPE/$FRAMEWORK/common/add_run_scripts.sh $FRAMEWORK $KEBOB $REPOSITORY $TEMPLATE $TYPE $USER

popd

echo "Completed $SCRIPT"
