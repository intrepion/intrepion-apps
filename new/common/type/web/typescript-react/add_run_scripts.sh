#!/usr/bin/env bash

SCRIPT=$0
FRAMEWORK=$1
KEBOB=$2
REPOSITORY=$3
TEMPLATE=$4

echo "Running $SCRIPT $FRAMEWORK $KEBOB $REPOSITORY $TEMPLATE"

pushd .

cd intrepion-apps

FOLDER=apps/$KEBOB/web

if [ ! -d $FOLDER ]; then
    mkdir -p $FOLDER
fi

FILE=$FOLDER/start_web-$FRAMEWORK-$TEMPLATE.sh

cat > $FILE <<EOF
#!/usr/bin/env bash

npm start --prefix ../$REPOSITORY
EOF

chmod +x $FILE
git add $FILE
git commit -m "Add run scripts."

popd

echo "Completed $SCRIPT $FRAMEWORK $KEBOB $REPOSITORY $TEMPLATE"
