#!/usr/bin/env bash

SCRIPT=$0
FRAMEWORK=$1
KEBOB=$2
REPOSITORY=$3
TEMPLATE=$4
TYPE=$5
USER=$6

echo "Running $SCRIPT $FRAMEWORK $KEBOB $REPOSITORY $TEMPLATE $TYPE $USER"

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

echo "Completed $SCRIPT $FRAMEWORK $KEBOB $REPOSITORY $TEMPLATE $TYPE $USER"
