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

TEMPLATE=web
APP=${PASCAL}Web
STACK=web-csharp-dotnet-$TEMPLATE
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

SOLUTION=${PASCAL}App
FILE=$SOLUTION.sln

if [ -f $FILE ]; then
    echo "File $FILE already exists."
    exit 1
fi

dotnet new sln --name $SOLUTION
exit_on_error $? !!
git add --all
exit_on_error $? !!
git commit --message="dotnet new sln --name $SOLUTION"
exit_on_error $? !!

LIBRARY=${PASCAL}Library
FOLDER=$LIBRARY

if [ -d $FOLDER ]; then
    echo "Directory $FOLDER already exists"
    exit 1
fi

dotnet new classlib --name $FOLDER
exit_on_error $? !!
git add --all
exit_on_error $? !!
git commit --message="dotnet new classlib --name $FOLDER"
exit_on_error $? !!
dotnet sln add $FOLDER
git add --all
exit_on_error $? !!
git commit --message="dotnet sln add $FOLDER"
exit_on_error $? !!

TESTS=${PASCAL}Tests
FOLDER=$TESTS

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
git add --all
exit_on_error $? !!
git commit --message="dotnet sln add $FOLDER"
exit_on_error $? !!
dotnet add $FOLDER reference $LIBRARY
git add --all
exit_on_error $? !!
git commit --message="dotnet add $FOLDER reference $LIBRARY"
exit_on_error $? !!

FOLDER=$APP

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
git add --all
exit_on_error $? !!
git commit --message="dotnet sln add $FOLDER"
exit_on_error $? !!
dotnet add $FOLDER reference $LIBRARY
git add --all
exit_on_error $? !!
git commit --message="dotnet add $FOLDER reference $LIBRARY"
exit_on_error $? !!

FILE=$APP/Program.cs

if [ ! -f $FILE ]; then
    echo "File $FILE does not exist."
    exit 1
fi

TEMP=${FILE}.tmp
cp $FILE $TEMP && awk '/app\.Run\(\);/ && c == 0 {c = 1; print "app.MapGet(\"/health_check\", () => \"\");\n"}; {print}' $TEMP > $FILE
rm $TEMP

FOLDER=.do

if [ -d $FOLDER ]; then
    echo "Directory $FOLDER already exists"
    exit 1
fi

mkdir $FOLDER

FILE=.do/app.yaml

if [ -f $FILE ]; then
    echo "File $FILE already exists."
    exit 1
fi

cat > $FILE <<EOF
name: app-web
region: sfo
services:
  - dockerfile_path: Dockerfile
    github:
      branch: main
      deploy_on_push: true
      repo: intrepion/$REPO
    health_check:
      http_path: /health_check
    http_port: 80
    instance_count: 1
    instance_size_slug: basic-xxs
    name: web
    routes:
      - path: /
    source_dir: /
EOF

FILE=.do/deploy.template.yaml

if [ -f $FILE ]; then
    echo "File $FILE already exists."
    exit 1
fi

cat > $FILE <<EOF
spec:
  name: app-web
  region: sfo
  services:
    - dockerfile_path: Dockerfile
      github:
        branch: main
        deploy_on_push: true
        repo: intrepion/$REPO
      health_check:
        http_path: /health_check
      http_port: 80
      instance_count: 1
      instance_size_slug: basic-xxs
      name: web
      routes:
        - path: /
      source_dir: /
EOF

FILE=Dockerfile

if [ -f $FILE ]; then
    echo "File $FILE already exists."
    exit 1
fi

cat > $FILE <<EOF
FROM mcr.microsoft.com/dotnet/sdk:7.0 AS build

WORKDIR /source

COPY *.sln .
COPY $LIBRARY/*.csproj ./$LIBRARY/
COPY $TESTS/*.csproj ./$TESTS/
COPY $APP/*.csproj ./$APP/
RUN dotnet restore

COPY $LIBRARY/. ./$LIBRARY/
COPY $TESTS/. ./$TESTS/
COPY $APP/. ./$APP/
WORKDIR /source/$APP
RUN dotnet publish -c release -o /app --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:7.0
WORKDIR /app
COPY --from=build /app ./
EXPOSE 80
ENTRYPOINT ["dotnet", "$APP.dll"]
EOF

FILE=README.md

cat << EOF >> $FILE

[![Deploy to DO](https://www.deploytodo.com/do-btn-blue.svg)](https://cloud.digitalocean.com/apps/new?repo=https://github.com/intrepion/$REPO/tree/main)
EOF

FOLDER=scripts

if [ -d $FOLDER ]; then
    echo "Directory $FOLDER already exists"
    exit 1
fi

mkdir $FOLDER

FILE=scripts/docker_build.sh

if [ -f $FILE ]; then
    echo "File $FILE already exists."
    exit 1
fi

cat > $FILE <<EOF
#!/usr/bin/env bash

sudo docker build --tag $REPO --file Dockerfile .
EOF

FILE=scripts/docker_run.sh

if [ -f $FILE ]; then
    echo "File $FILE already exists."
    exit 1
fi

cat > $FILE <<EOF
#!/usr/bin/env bash

sudo docker run -p 80:80 $REPO
EOF

FILE=scripts/docker_system_prune.sh

if [ -f $FILE ]; then
    echo "File $FILE already exists."
    exit 1
fi

cat > $FILE <<EOF
#!/usr/bin/env bash

sudo docker system prune --all --force
EOF

FILE=scripts/doctl_apps_create.sh

if [ -f $FILE ]; then
    echo "File $FILE already exists."
    exit 1
fi

cat > $FILE <<EOF
#!/usr/bin/env bash

doctl apps create --spec .do/app.yaml
EOF

FILE=scripts/doctl_apps_update.sh

if [ -f $FILE ]; then
    echo "File $FILE already exists."
    exit 1
fi

cat > $FILE <<EOF
#!/usr/bin/env bash

doctl apps update $1 --spec .do/app.yaml
EOF

FILE=scripts/dotnet_watch.sh

if [ -f $FILE ]; then
    echo "File $FILE already exists."
    exit 1
fi

cat > $FILE <<EOF
#!/usr/bin/env bash

dotnet watch test --project $TESTS
EOF

chmod +x $FOLDER/*.sh
exit_on_error $? !!

git add --all
exit_on_error $? !!
git commit --message="Added Digital Ocean files."
exit_on_error $? !!

cd ../intrepion-apps

FOLDER=apps/$KEBOB/web

if [ ! -d $FOLDER ]; then
    mkdir -p $FOLDER
fi

FILE=$FOLDER/start_$STACK.sh

cat > $FILE <<EOF
#!/usr/bin/env bash

dotnet run --project ../intrepion-$KEBOB-$STACK/$APP
EOF
chmod +x $FILE
exit_on_error $? !!
git add $FILE
exit_on_error $? !!
git commit -m "$SCRIPT $KEBOB $PASCAL"
exit_on_error $? !!

echo "$SCRIPT $KEBOB $PASCAL successful."
