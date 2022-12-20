#!/usr/bin/env bash

exit_on_error() {
    exit_code=$1
    last_command=${@:2}
    if [ $exit_code -ne 0 ]; then
        >&2 echo "\"${last_command}\" command failed with exit code ${exit_code}."
        exit $exit_code
    fi
}

set -o history -o histexpand

APP=$1
KEBOB=$2
PASCAL=$3
REPO=$4
SCRIPT=$5
STACK=$6

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
git commit -m "$SCRIPT $KEBOB $PASCAL"

popd
