#!/bin/bash

SCRIPT=$0
PASCAL=$1
REPOSITORY=$2

echo "$SCRIPT $PASCAL $REPOSITORY"

pushd .

cd $REPOSITORY

# Check if the README.md file has the text "## Commands"
if ! grep -q "## Commands" README.md; then
  # If the text is not found, append it to the end of the file along with instructions on how to build, test, and run a dotnet web application
  echo -e "\n\n## Commands\n\nTo build the project:\n\n\`\`\`bash\ndotnet build\n\`\`\`\n\nTo run tests:\n\n\`\`\`bash\ndotnet test\n\`\`\`\n\nTo run the web application:\n\n\`\`\`bash\ndotnet run --project ${PASCAL}App\n\`\`\`" >> README.md
  git add README.md
  git commit -m "Added commands section to README file.";
fi

popd
