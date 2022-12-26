#!/usr/bin/env bash

SCRIPT=$0
CURRENT=$1
PASCAL=$2
REPOSITORY=$3
USER=$4

echo "$SCRIPT $CURRENT $PASCAL $REPOSITORY $USER"

source ./intrepion-apps/new/functions.sh

pushd .

cd $REPOSITORY

FOLDER=.do

exit_if_folder_exists $FOLDER

mkdir $FOLDER

FILE=.do/app.yaml

exit_if_file_exists $FILE

cat > $FILE <<EOF
name: app-web
region: sfo
services:
  - dockerfile_path: Dockerfile
    github:
      branch: $CURRENT
      deploy_on_push: true
      repo: $USER/$REPOSITORY
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

exit_if_file_exists $FILE

cat > $FILE <<EOF
spec:
  name: app-web
  region: sfo
  services:
    - dockerfile_path: Dockerfile
      github:
        branch: $CURRENT
        deploy_on_push: true
        repo: $USER/$REPOSITORY
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

exit_if_file_exists $FILE

cat > $FILE <<EOF
FROM mcr.microsoft.com/dotnet/sdk:7.0 AS build

WORKDIR /source

COPY ${PASCAL}App.sln .
COPY ${PASCAL}Library/*.csproj ./${PASCAL}Library/
COPY ${PASCAL}Tests/*.csproj ./${PASCAL}Tests/
COPY ${PASCAL}Web/*.csproj ./${PASCAL}Web/
RUN dotnet restore

COPY ${PASCAL}Library/. ./${PASCAL}Library/
COPY ${PASCAL}Tests/. ./${PASCAL}Tests/
COPY ${PASCAL}Web/. ./${PASCAL}Web/
WORKDIR /source/$PROJECT
RUN dotnet publish -c release -o /app --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:7.0
WORKDIR /app
COPY --from=build /app ./
EXPOSE 80
ENTRYPOINT ["dotnet", "$PROJECT.dll"]
EOF

FILE=README.md

exist_if_file_does_not_exist $FILE

cat << EOF >> $FILE


[![Deploy to DO](https://www.deploytodo.com/do-btn-blue.svg)](https://cloud.digitalocean.com/apps/new?repo=https://github.com/intrepion/$REPOSITORY/tree/$CURRENT)
EOF

FOLDER=scripts

exit_if_folder_exists $FOLDER

mkdir $FOLDER

FILE=scripts/docker_build.sh

exit_if_file_exists $FILE

cat > $FILE <<EOF
#!/usr/bin/env bash

sudo docker build --tag $REPOSITORY --file Dockerfile .
EOF

FILE=scripts/docker_run.sh

exit_if_file_exists $FILE

cat > $FILE <<EOF
#!/usr/bin/env bash

sudo docker run -p 80:80 $REPOSITORY
EOF

FILE=scripts/docker_system_prune.sh

exit_if_file_exists $FILE

cat > $FILE <<EOF
#!/usr/bin/env bash

sudo docker system prune --all --force
EOF

FILE=scripts/doctl_apps_create.sh

exit_if_file_exists $FILE

cat > $FILE <<EOF
#!/usr/bin/env bash

doctl apps create --spec .do/app.yaml
EOF

FILE=scripts/doctl_apps_update.sh

exit_if_file_exists $FILE

cat > $FILE <<EOF
#!/usr/bin/env bash

doctl apps update $1 --spec .do/app.yaml
EOF

FILE=scripts/dotnet_watch.sh

exit_if_file_exists $FILE

cat > $FILE <<EOF
#!/usr/bin/env bash

dotnet watch test --project ${PASCAL}Tests
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
