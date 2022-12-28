#!/usr/bin/env bash

SCRIPT=$0
PASCAL=$1
PROJECT=$2
REPOSITORY=$3
USER=$4

echo "Running $SCRIPT $PASCAL $PROJECT $REPOSITORY $USER"

pushd .

cd $REPOSITORY

mkdir .do

cat > .do/app.yaml <<EOF
name: app-web
region: sfo
services:
  - dockerfile_path: Dockerfile
    github:
      branch: main
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

cat > .do/deploy.template.yaml <<EOF
spec:
  name: app-web
  region: sfo
  services:
    - dockerfile_path: Dockerfile
      github:
        branch: main
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

cat > Dockerfile <<EOF
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

cat << EOF >> README.md

## Deploy

### Digital Ocean

[![Deploy to DO](https://www.deploytodo.com/do-btn-blue.svg)](https://cloud.digitalocean.com/apps/new?repo=https://github.com/$USER/$REPOSITORY/tree/main)
EOF

mkdir scripts

cat > scripts/docker_build.sh <<EOF
#!/usr/bin/env bash

sudo docker build --tag $REPOSITORY --file Dockerfile .
EOF

cat > scripts/docker_run.sh <<EOF
#!/usr/bin/env bash

sudo docker run -p 80:80 $REPOSITORY
EOF

cat > scripts/docker_system_prune.sh <<EOF
#!/usr/bin/env bash

sudo docker system prune --all --force
EOF

cat > scripts/doctl_apps_create.sh <<EOF
#!/usr/bin/env bash

doctl apps create --spec .do/app.yaml
EOF

cat > scripts/doctl_apps_update.sh <<EOF
#!/usr/bin/env bash

doctl apps update \$1 --spec .do/app.yaml
EOF

cat > scripts/dotnet_watch.sh <<EOF
#!/usr/bin/env bash

dotnet watch test --project ${PASCAL}Tests
EOF

chmod +x scripts/*.sh

git add --all
git commit --message="Added Digital Ocean files."

popd

echo "Completed $SCRIPT $PASCAL $PROJECT $REPOSITORY $USER"
