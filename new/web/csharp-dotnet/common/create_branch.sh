#!/bin/bash

SCRIPT=$0
CURRENT=$1
REPOSITORY=$2
USER=$3

echo "$SCRIPT $CURRENT $REPOSITORY $USER"

pushd .

# Check if the specified folder exists
if [ ! -d "$REPOSITORY" ]; then
  # If the folder does not exist, clone the repository using SSH
  git clone git@github.com:$USER/$REPOSITORY.git
fi

# Navigate to the repository folder
cd $REPOSITORY

git checkout main

# Check if the README.md file has the text "## Branches"
if grep -q "## Branches" README.md; then
  # If the text is found, insert the link to the branch at the top of the section, making sure to include a blank line between the section title and the list of links
  echo "File README.md contains the line '## Branches'"
  sed -i '/## Branches/{n;d}' README.md
  sed -i "/## Branches/a\
\
- [$CURRENT](https://github.com/$USER/$REPOSITORY/tree/$CURRENT)" README.md
else
  # If the text is not found, append it to the end of the file along with a link to a branch with the current date and time as the name
  echo "File README.md does not contain the line '## Branches'"
  echo -e "\n## Branches\n\n- [$CURRENT](https://github.com/$USER/$REPOSITORY/tree/$CURRENT)" >> README.md
fi

git add README.md
git commit -m "Added branch $CURRENT to README file."
git push

FIRST=`git rev-list --max-parents=0 HEAD`
git checkout $FIRST

# Create a new branch with the current date and time as the name
git checkout -b $CURRENT
git push --set-upstream origin $CURRENT

popd
