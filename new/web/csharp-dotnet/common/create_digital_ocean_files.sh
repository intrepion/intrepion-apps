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
LIBRARY=$2
REPO=$3
TESTS=$4

pushd .

cd $REPO

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
      http_path: /HealthCheck
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
git push
exit_on_error $? !!

popd
