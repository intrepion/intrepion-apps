#!/usr/bin/env bash

SCRIPT=$0

echo " - Running $SCRIPT"

pushd .

cd ..
pwd

CLIENT="http://localhost:3000"
CLIENT_FRAMEWORK=typescript-react
CLIENT_TEMPLATE=typescript
KEBOB=klondike
PASCAL=Klondike
SERVER_FRAMEWORK=csharp-dotnet
SERVER_TEMPLATE=webapi

CLIENT_REPOSITORY=intrepion-$KEBOB-json-rpc-client-web-$CLIENT_FRAMEWORK-$CLIENT_TEMPLATE
PROJECT=${PASCAL}WebApi
SERVER_REPOSITORY=intrepion-$KEBOB-json-rpc-server-$SERVER_FRAMEWORK-$SERVER_TEMPLATE

REPOSITORY=$SERVER_REPOSITORY

# type - the works
./intrepion-apps/new/common/type/full_stack/jwt/$SERVER_FRAMEWORK/$SERVER_TEMPLATE/the_works.sh $CLIENT $SERVER_FRAMEWORK $KEBOB $PASCAL $PROJECT $SERVER_REPOSITORY $SERVER_TEMPLATE

# project - code
cd $REPOSITORY
pwd

FILE=$PROJECT/Properties/launchSettings.json
SERVER=$(jq '.profiles.http.applicationUrl' $FILE)

git push --force

cd ..
