#!/usr/bin/env bash

SCRIPT=$0
CLIENT=$1
KEBOB=$2
PROJECT=$3
SERVER=$4

echo "Running $SCRIPT $CLIENT $KEBOB $PROJECT $SERVER"

pushd .

cd intrepion-apps

FOLDER=apps/$KEBOB/json-rpc/server

if [ ! -d $FOLDER ]; then
    mkdir -p $FOLDER
fi

FILE=$FOLDER/start_server-csharp-dotnet-webapi.sh

cat > $FILE <<EOF
#!/usr/bin/env bash

CLIENT_URL=\$1 dotnet run --project ../intrepion-$KEBOB-json-rpc-server-csharp-dotnet-webapi/$PROJECT
EOF

chmod +x $FILE
git add $FILE

FOLDER=apps/$KEBOB/json-rpc/client-web

if [ ! -d $FOLDER ]; then
    mkdir -p $FOLDER
fi

FILE=$FOLDER/start_client-web-typescript-react-typescript.sh

cat > $FILE <<EOF
#!/usr/bin/env bash

REACT_APP_SERVER_URL=\$1 npm start --prefix ../intrepion-$KEBOB-json-rpc-client-web-typescript-react-typescript
EOF

chmod +x $FILE
git add $FILE

FOLDER=apps/$KEBOB/json-rpc/full_stack/typescript-react-csharp-dotnet

if [ ! -d $FOLDER ]; then
    mkdir -p $FOLDER
fi

FILE=$FOLDER/start_full_stack-typescript-webapi_server.sh

cat > $FILE <<EOF
#!/usr/bin/env bash

./apps/$KEBOB/json-rpc/server/start_server-csharp-dotnet-webapi.sh "$CLIENT"
EOF

chmod +x $FILE
git add $FILE

FILE=$FOLDER/start_full_stack-typescript-webapi_client.sh

cat > $FILE <<EOF
#!/usr/bin/env bash

./apps/$KEBOB/json-rpc/client-web/start_client-web-typescript-react-typescript.sh "$SERVER"
EOF

chmod +x $FILE
git add $FILE

git commit -m "Add run scripts."

popd

echo "Completed $SCRIPT $CLIENT $KEBOB $PROJECT $SERVER"
