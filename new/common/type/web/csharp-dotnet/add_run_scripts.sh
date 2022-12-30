#!/usr/bin/env bash

SCRIPT=$0
FRAMEWORK=$1
KEBOB=$2
PROJECT=$3
REPOSITORY=$4
TEMPLATE=$5

echo "Running $SCRIPT $FRAMEWORK $KEBOB $PROJECT $REPOSITORY $TEMPLATE"

pushd .

cd intrepion-apps

FOLDER=apps/$KEBOB/web

if [ ! -d $FOLDER ]; then
    mkdir -p $FOLDER
fi

FILE=$FOLDER/start_web-$FRAMEWORK-$TEMPLATE.sh

cat > $FILE << EOF
#!/usr/bin/env bash

dotnet run --project ../$REPOSITORY/$PROJECT
EOF

chmod +x $FILE
git add $FILE
git commit -m "Add run scripts."

popd

echo "Completed $SCRIPT $FRAMEWORK $KEBOB $PROJECT $REPOSITORY $TEMPLATE"
