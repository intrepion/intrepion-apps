#!/usr/bin/env bash

exit_on_error() {
    exit_code=$1
    last_command=${@:2}
    if [ $exit_code -ne 0 ]; then
        >&2 echo "\"${last_command}\" command failed with exit code ${exit_code}."
        exit $exit_code
    fi
}

# enable !! command completion
set -o history -o histexpand

SCRIPT=$0
KEBOB=$1
PASCAL=$2

if [ -z $KEBOB ]; then
    echo "usage: $SCRIPT <kebob-case> <PascalCase>"
    exit 1
fi

if [ -z $PASCAL ]; then
    echo "usage: $SCRIPT <kebob-case> <PascalCase>"
    exit 1
fi

STACK=web-csharp-dotnet-web
REPO=intrepion-$KEBOB-$STACK

cd ..

FOLDER=$REPO

if [ -d $FOLDER ]; then
    echo "Directory $FOLDER already exists"
    exit 1
fi

git clone git@github.com:intrepion/$REPO.git
exit_on_error $? !!

cd $REPO
exit_on_error $? !!

FILE=.gitignore

if [ -f $FILE ]; then
    echo "File $FILE already exists."
    exit 1
fi

dotnet new gitignore
exit_on_error $? !!
git add --all
exit_on_error $? !!
git commit --message="dotnet new gitignore"
exit_on_error $? !!

FILE=$PASCAL.sln

if [ -f $FILE ]; then
    echo "File $FILE already exists."
    exit 1
fi

dotnet new sln --name $PASCAL
exit_on_error $? !!
git add --all
exit_on_error $? !!
git commit --message="dotnet new sln"
exit_on_error $? !!

LIBRARY=${PASCAL}Library
FOLDER=$LIBRARY

if [ -d $FOLDER ]; then
    echo "Directory $FOLDER already exists"
    exit 1
fi

dotnet new classlib --name $LIBRARY
exit_on_error $? !!
git add --all
exit_on_error $? !!
git commit --message="dotnet new classlib --name $LIBRARY"
exit_on_error $? !!
dotnet sln add $LIBRARY
exit_on_error $? !!
git add --all
exit_on_error $? !!
git commit --message="dotnet sln add $LIBRARY"
exit_on_error $? !!

FOLDER=${PASCAL}Tests

if [ -d $FOLDER ]; then
    echo "Directory $FOLDER already exists"
    exit 1
fi

dotnet new xunit --name $FOLDER
exit_on_error $? !!
git add --all
exit_on_error $? !!
git commit --message="dotnet new xunit --name $FOLDER"
exit_on_error $? !!
dotnet sln add $FOLDER
exit_on_error $? !!
git add --all
exit_on_error $? !!
git commit --message="dotnet sln add $FOLDER"
exit_on_error $? !!
dotnet add $FOLDER reference $LIBRARY
exit_on_error $? !!
git add --all
exit_on_error $? !!
git commit --message="dotnet add $FOLDER reference $LIBRARY"
exit_on_error $? !!

FOLDER=${PASCAL}Web

if [ -d $FOLDER ]; then
    echo "Directory $FOLDER already exists"
    exit 1
fi

dotnet new web --name $FOLDER
exit_on_error $? !!
git add --all
exit_on_error $? !!
git commit --message="dotnet new web --name $FOLDER"
exit_on_error $? !!
dotnet sln add $FOLDER
exit_on_error $? !!
git add --all
exit_on_error $? !!
git commit --message="dotnet sln add $FOLDER"
exit_on_error $? !!
dotnet add $FOLDER reference $LIBRARY
exit_on_error $? !!
git add --all
exit_on_error $? !!
git commit --message="dotnet add $FOLDER reference $LIBRARY"
exit_on_error $? !!

git push
exit_on_error $? !!

cd ../intrepion-apps

FOLDER=apps/$KEBOB/web

if [ ! -d $FOLDER ]; then
    mkdir -p $FOLDER
fi

FILE=$FOLDER/start_$STACK.sh

if [ -f $FILE ]; then
    echo "File $FILE already exists."
    exit 1
fi

cat > $FILE <<EOF
#!/usr/bin/env bash

dotnet run --project ../intrepion-$KEBOB-web-csharp-dotnet-web/${PASCAL}Web
EOF
chmod +x $FILE
git add $FILE
git commit -m "$SCRIPT $KEBOB $PASCAL"

echo "$SCRIPT $KEBOB $PASCAL successful."
