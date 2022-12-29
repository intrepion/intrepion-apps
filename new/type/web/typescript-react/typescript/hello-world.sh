#!/usr/bin/env bash

SCRIPT=$0

echo "Running $SCRIPT"

pushd .

cd ..

FRAMEWORK=typescript-react
KEBOB=hello-world
PASCAL=HelloWorld
TEMPLATE=typescript

REPOSITORY=intrepion-$KEBOB-web-$FRAMEWORK-$TEMPLATE

# framework - the works
./intrepion-apps/new/common/framework/$FRAMEWORK/$TEMPLATE/the_works.sh $FRAMEWORK $REPOSITORY $TEMPLATE

# project - add hello world
cd $REPOSITORY

FILE=src/App.tsx

sed -i 's/  return <><\/>;/  return <>Hello, world!<\/>;/' $FILE
npx prettier --write .
git add $FILE
git commit --message "Added hello world text."
git push --force

cd ..

# type - add run scripts
./intrepion-apps/new/common/type/web/$FRAMEWORK/add_run_scripts.sh $FRAMEWORK $KEBOB $REPOSITORY $TEMPLATE

popd

echo "Completed $SCRIPT"
