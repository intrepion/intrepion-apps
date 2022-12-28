#!/usr/bin/env bash

SCRIPT=$0

echo "Running $SCRIPT"

pushd .

cd ..

FRAMEWORK=typescript-react
KEBOB=hello-world
PASCAL=HelloWorld
TEMPLATE=typescript
TYPE=web
USER=intrepion

REPOSITORY=$USER-$KEBOB-$TYPE-$FRAMEWORK-$TEMPLATE

# framework - the works
./$USER-apps/new/common/$FRAMEWORK/$TEMPLATE/the_works.sh $FRAMEWORK $REPOSITORY $TEMPLATE $USER

# project - add hello world
cd $REPOSITORY

FILE=src/App.tsx

sed -i 's/  return <><\/>;/  return <>Hello, world!<\/>;/' $FILE
git add $FILE
git commit --message "Added hello world text."
git push --force

cd ..

# framework - add run scripts
./$USER-apps/new/common/$FRAMEWORK/common/add_run_scripts.sh $FRAMEWORK $KEBOB $REPOSITORY $TEMPLATE $TYPE $USER

popd

echo "Completed $SCRIPT"
