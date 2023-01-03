#!/bin/bash

SCRIPT=$0
REPOSITORY=$1
SERVER=$2

echo "Running $SCRIPT $REPOSITORY $SERVER"

pushd .

cd $REPOSITORY
pwd

cat << EOF >> README.md

## Commands

### Install

\`\`\`bash
npm install
\`\`\`

### Test

\`\`\`bash
npm test
\`\`\`

### Initialize Database

\`\`\`bash
./scripts/init_postgres.sh
\`\`\`

### Run

\`\`\`bash
REACT_APP_SERVER_URL=$SERVER npm start
\`\`\`
EOF

git add README.md
git commit -m "Added commands section to README file.";

popd

echo "Completed $SCRIPT $REPOSITORY $SERVER"
