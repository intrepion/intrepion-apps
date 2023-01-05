#!/usr/bin/env bash

SCRIPT=$0
NAME=$1
PASCAL=$2
PROJECT=$3
REPOSITORY=$4

echo " - Running $SCRIPT $NAME $PASCAL $PROJECT $REPOSITORY"

if [ $# -ne 4 ]; then
  echo "usage: $SCRIPT <NAME> <PASCAL> <PROJECT> <REPOSITORY>"
  exit 1
fi

pushd .

cd $REPOSITORY
pwd

mkdir -p .do

FILE=.do/app.yaml

cat > $FILE << EOF
name: app-$NAME
region: sfo
services:
  - dockerfile_path: Dockerfile
    github:
      branch: main
      deploy_on_push: true
      repo: intrepion/$REPOSITORY
    health_check:
      http_path: /HealthCheck
    http_port: 80
    instance_count: 1
    instance_size_slug: basic-xxs
    name: $NAME
    routes:
      - path: /
    source_dir: /
EOF

git add $FILE

FILE=.do/deploy.template.yaml

cat > $FILE << EOF
spec:
  name: app-$NAME
  region: sfo
  services:
    - dockerfile_path: Dockerfile
      github:
        branch: main
        deploy_on_push: true
        repo: intrepion/$REPOSITORY
      health_check:
        http_path: /health_check
      http_port: 80
      instance_count: 1
      instance_size_slug: basic-xxs
      name: $NAME
      routes:
        - path: /
      source_dir: /
EOF

git add $FILE

FILE=Dockerfile

cat > $FILE << EOF
FROM mcr.microsoft.com/dotnet/sdk:7.0 AS build

WORKDIR /source

COPY ${PASCAL}App.sln .
COPY ${PASCAL}Library/*.csproj ./${PASCAL}Library/
COPY ${PASCAL}Tests/*.csproj ./${PASCAL}Tests/
COPY $PROJECT/*.csproj ./$PROJECT/
RUN dotnet restore

COPY ${PASCAL}Library/. ./${PASCAL}Library/
COPY ${PASCAL}Tests/. ./${PASCAL}Tests/
COPY $PROJECT/. ./$PROJECT/
WORKDIR /source/$PROJECT
RUN dotnet publish -c release -o /app --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:7.0
WORKDIR /app
COPY --from=build /app ./
EXPOSE 80
ENTRYPOINT ["dotnet", "$PROJECT.dll"]
EOF

git add $FILE

FILE=README.md

cat << EOF >> $FILE

## Deploy

### Digital Ocean

[![Deploy to DO](https://www.deploytodo.com/do-btn-blue.svg)](https://cloud.digitalocean.com/apps/new?repo=https://github.com/intrepion/$REPOSITORY/tree/main)
EOF

git add $FILE

mkdir scripts

FILE=scripts/docker_build.sh

cat > $FILE << EOF
#!/usr/bin/env bash

sudo docker build --tag $REPOSITORY --file Dockerfile .
EOF

chmod +x $FILE
git add $FILE

FILE=scripts/docker_run.sh

cat > $FILE << EOF
#!/usr/bin/env bash

sudo docker run -p 80:80 $REPOSITORY
EOF

chmod +x $FILE
git add $FILE

FILE=scripts/docker_system_prune.sh

cat > $FILE << EOF
#!/usr/bin/env bash

sudo docker system prune --all --force
EOF

chmod +x $FILE
git add $FILE

FILE=scripts/doctl_apps_create.sh

cat > $FILE << EOF
#!/usr/bin/env bash

doctl apps create --spec .do/app.yaml
EOF

chmod +x $FILE
git add $FILE

FILE=scripts/doctl_apps_update.sh

cat > $FILE << EOF
#!/usr/bin/env bash

doctl apps update \$1 --spec .do/app.yaml
EOF

chmod +x $FILE
git add $FILE

FILE=scripts/dotnet_watch.sh

cat > $FILE << EOF
#!/usr/bin/env bash

dotnet watch test --project ${PASCAL}Tests
EOF

chmod +x $FILE
git add $FILE

git commit --message="Added Digital Ocean files."

popd

echo " - Completed $SCRIPT $NAME $PASCAL $PROJECT $REPOSITORY"
