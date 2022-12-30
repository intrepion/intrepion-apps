#!/usr/bin/env bash

SCRIPT=$0
NAME=$1
REPOSITORY=$2

echo "Running $SCRIPT $NAME $REPOSITORY"

pushd .

cd $REPOSITORY

mkdir .do

cat > .do/app.yaml << EOF
name: app-$NAME
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

cat > .do/deploy.template.yaml << EOF
spec:
  name: app-$NAME
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

cat << EOF >> README.md

## Deploy

### Digital Ocean

[![Deploy to DO](https://www.deploytodo.com/do-btn-blue.svg)](https://cloud.digitalocean.com/apps/new?repo=https://github.com/intrepion/$REPOSITORY/tree/main)
EOF

mkdir scripts

cat > scripts/doctl_apps_create.sh << EOF
#!/usr/bin/env bash

doctl apps create --spec .do/app.yaml
EOF

cat > scripts/doctl_apps_update.sh << EOF
#!/usr/bin/env bash

doctl apps update \$1 --spec .do/app.yaml
EOF

chmod +x scripts/*.sh

git add --all
git commit --message="Added Digital Ocean files."

popd

echo "Completed $SCRIPT $NAME $REPOSITORY"
