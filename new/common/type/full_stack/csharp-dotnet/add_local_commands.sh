#!/bin/bash

SCRIPT=$0
CLIENT=$1
PROJECT=$2
REPOSITORY=$3

echo " - Running $SCRIPT $CLIENT $PROJECT $REPOSITORY"

if [ $# -ne 3 ]; then
  echo "usage: $SCRIPT <CLIENT> <PROJECT> <REPOSITORY>"
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
CLIENT_URL="$CLIENT" dotnet run --project ${PROJECT}
\`\`\`
EOF
git add $FILE

git commit -m "Added commands section to README file.";

popd

echo " - Completed $SCRIPT $CLIENT $PROJECT $REPOSITORY"
