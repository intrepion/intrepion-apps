#!/usr/bin/env bash

SCRIPT=$0
KEBOB=$1
PROJECT=$2
REPOSITORY=$3
STACK=$4

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

dotnet run --project ../$REPOSITORY/$PROJECT
EOF

chmod +x $FILE
exit_on_error $? !!
git add $FILE
exit_on_error $? !!
git commit -m "$SCRIPT $KEBOB"

popd
