#!/bin/bash

SCRIPT=$0
PROJECT=$1
REPOSITORY=$2

echo "Running $SCRIPT $PROJECT $REPOSITORY"

pushd .

cd $REPOSITORY

cat << EOF >> README.md

## Commands

### Build

\`\`\`bash
dotnet build
\`\`\`

### Test

\`\`\`bash
dotnet test
\`\`\`

### Run

\`\`\`bash
dotnet run --project ${PROJECT}
\`\`\`
EOF

git add README.md
git commit -m "Added commands section to README file.";

popd

echo "Completed $SCRIPT $PROJECT $REPOSITORY"
