#!/usr/bin/env bash

SCRIPT=$0
KEBOB=$1
NAME=$2
REPOSITORY=$3

echo " - Running $SCRIPT $KEBOB $NAME $REPOSITORY"

if [ $# -ne 3 ]; then
  echo "usage: $SCRIPT <KEBOB> <NAME> <REPOSITORY>"
  exit 1
fi

pushd .

cd $REPOSITORY
pwd

mkdir -p .do

FILE=.do/app.yaml
cat > $FILE << EOF
name: $KEBOB-$NAME
region: sfo
static_sites:
  - build_command: npm run build
    environment_slug: node-js
    github:
      branch: main
      deploy_on_push: true
      repo: intrepion/$REPOSITORY
    name: $NAME
    routes:
      - path: /
    source_dir: /
EOF
git add $FILE

FILE=.do/deploy.template.yaml
cat > $FILE << EOF
spec:
  name: $KEBOB-$NAME
  region: sfo
  static_sites:
    - build_command: npm run build
      environment_slug: node-js
      github:
        branch: main
        deploy_on_push: true
        repo: intrepion/$REPOSITORY
      name: $NAME
      routes:
        - path: /
      source_dir: /
EOF
git add $FILE

FILE=README.md

cat << EOF >> $FILE

## Deploy

### Digital Ocean

[![Deploy to DO](https://www.deploytodo.com/do-btn-blue.svg)](https://cloud.digitalocean.com/apps/new?repo=https://github.com/intrepion/$REPOSITORY/tree/main)
EOF
git add $FILE

mkdir -p scripts

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
git commit --message="Added Digital Ocean files."

popd

echo " - Completed $SCRIPT $KEBOB $NAME $REPOSITORY"
