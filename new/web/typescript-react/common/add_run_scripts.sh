#!/usr/bin/env bash

SCRIPT=$0
FRAMEWORK=$1
KEBOB=$2
PROJECT=$3
REPOSITORY=$4
TEMPLATE=$5
TYPE=$6
USER=$7

echo "Running $SCRIPT $FRAMEWORK $KEBOB $PROJECT $REPOSITORY $TEMPLATE $TYPE $USER"

pushd .

cd intrepion-apps

FOLDER=apps/$KEBOB/$TYPE

if [ ! -d $FOLDER ]; then
    mkdir -p $FOLDER
fi

FILE=$FOLDER/start_$TYPE-$FRAMEWORK-$TEMPLATE.sh

cat > $FILE <<EOF
#!/usr/bin/env bash

npm start --prefix ../$REPOSITORY
EOF

chmod +x $FILE
git add $FILE
git commit -m "$SCRIPT $KEBOB"

popd

echo "Completed $SCRIPT $FRAMEWORK $KEBOB $PROJECT $REPOSITORY $TEMPLATE $TYPE $USER"
