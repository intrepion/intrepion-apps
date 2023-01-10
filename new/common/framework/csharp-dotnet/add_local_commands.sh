#!/bin/bash

SCRIPT=$0
PROJECT=$1
REPOSITORY=$2

echo " - Running $SCRIPT $PROJECT $REPOSITORY"

if [ $# -ne 2 ]; then
  echo "usage: $SCRIPT <PROJECT> <REPOSITORY>"
  exit 1
fi

pushd .

cd $REPOSITORY
pwd

FILE=README.md
cat << EOF >> $FILE


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
git add $FILE

git commit -m "Added commands section to README file.";

popd

echo " - Completed $SCRIPT $PROJECT $REPOSITORY"
