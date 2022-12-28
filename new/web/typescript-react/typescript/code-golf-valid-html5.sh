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

# framework - the works
./$USER-apps/new/common/framework/$FRAMEWORK/$TEMPLATE/the_works.sh $FRAMEWORK $REPOSITORY $TEMPLATE $USER

# project - add minimal html5 to pass validation
cd $REPOSITORY

git push --force

cd ..

# type - add run scripts
./$USER-apps/new/common/type/$TYPE/$FRAMEWORK/add_run_scripts.sh $FRAMEWORK $KEBOB $REPOSITORY $TEMPLATE $TYPE $USER

popd

echo "Completed $SCRIPT"
