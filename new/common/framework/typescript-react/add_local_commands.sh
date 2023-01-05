#!/bin/bash

SCRIPT=$0
REPOSITORY=$1

echo " - Running $SCRIPT $REPOSITORY"

if [ $# -ne 1 ]; then
  echo "usage: $SCRIPT <REPOSITORY>"
  exit 1
fi

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

### Run

\`\`\`bash
npm start
\`\`\`
EOF

git add README.md
git commit -m "Added commands section to README file.";

popd

echo " - Completed $SCRIPT $REPOSITORY"
