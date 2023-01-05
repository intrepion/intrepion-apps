#!/usr/bin/env bash

SCRIPT=$0

echo " - Running $SCRIPT"

pushd .

cd ..

FRAMEWORK=typescript-react
KEBOB=code-golf-valid-html5
TEMPLATE=typescript

REPOSITORY=intrepion-$KEBOB-web-$FRAMEWORK-$TEMPLATE

# framework - the works
./intrepion-apps/new/common/framework/$FRAMEWORK/$TEMPLATE/the_works.sh $FRAMEWORK $REPOSITORY $TEMPLATE

# project - add minimal html5 to pass validation
cd $REPOSITORY
pwd

git push --force

cd ..

# type - add run scripts
./intrepion-apps/new/common/type/web/$FRAMEWORK/add_run_scripts.sh $FRAMEWORK $KEBOB $REPOSITORY $TEMPLATE

popd

echo " - Completed $SCRIPT"
