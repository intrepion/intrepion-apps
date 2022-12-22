#!/usr/bin/env bash

APP=$1
KEBOB=$2
REPO=$3
SCRIPT=$4
STACK=$5

source ./intrepion-apps/new/functions.sh

pushd .

cd intrepion-apps

FOLDER=apps/$KEBOB/web

if [ ! -d $FOLDER ]; then
    mkdir -p $FOLDER
fi

FILE=$FOLDER/start_$STACK.sh

cat > $FILE <<EOF
#!/usr/bin/env bash

dotnet run --project ../$REPO/$APP
EOF

chmod +x $FILE
exit_on_error $? !!
git add $FILE
exit_on_error $? !!
git commit -m "$SCRIPT $KEBOB"

popd
