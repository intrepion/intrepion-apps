#!/usr/bin/env bash

SCRIPT=$0
REPOSITORY=$1
USER=$2

echo "Running $SCRIPT $REPOSITORY $USER"

pushd .

cd $REPOSITORY

mkdir .do

cat > .do/app.yaml <<EOF
name: app-web
region: sfo
static_sites:
  - build_command: npm run build
    environment_slug: node-js
    github:
      branch: main
      deploy_on_push: true
      repo: $USER/$REPOSITORY
    name: web
    routes:
      - path: /
    source_dir: /
EOF

cat > .do/deploy.template.yaml <<EOF
spec:
  name: app-web
  region: sfo
  static_sites:
    - build_command: npm run build
      environment_slug: node-js
      github:
        branch: main
        deploy_on_push: true
        repo: $USER/$REPOSITORY
      name: web
      routes:
        - path: /
      source_dir: /

EOF

cat << EOF >> README.md

## Deploy

### Digital Ocean

[![Deploy to DO](https://www.deploytodo.com/do-btn-blue.svg)](https://cloud.digitalocean.com/apps/new?repo=https://github.com/$USER/$REPOSITORY/tree/main)
EOF

mkdir scripts

cat > scripts/doctl_apps_create.sh <<EOF
#!/usr/bin/env bash

doctl apps create --spec .do/app.yaml
EOF

cat > scripts/doctl_apps_update.sh <<EOF
#!/usr/bin/env bash

doctl apps update \$1 --spec .do/app.yaml
EOF

chmod +x scripts/*.sh

git add --all
git commit --message="Added Digital Ocean files."

popd

echo "Completed $SCRIPT $REPOSITORY $USER"
