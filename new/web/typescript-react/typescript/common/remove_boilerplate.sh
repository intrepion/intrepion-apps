#!/usr/bin/env bash

SCRIPT=$0
REPOSITORY=$1

echo "Running $SCRIPT $REPOSITORY"

pushd .

cd $REPOSITORY

FILE=src/App.tsx

cat > $FILE <<EOF
import React from "react";

function App() {
  return <></>;
}

export default App;

EOF

git add $FILE
git commit --message="Added health check."

FILE=src/App.css
rm -rf $FILE
git add $FILE

FILE=src/App.test.tsx
rm -rf $FILE
git add $FILE

FILE=src/index.css
rm -rf $FILE
git add $FILE

FILE=src/index.tsx
sed -i '/import ".\/index.css";/d' $FILE
git add $FILE

FILE=src/logo.svg
rm -rf $FILE
git add $FILE

git commit --message="Removed boilerplate."

popd

echo "Completed $SCRIPT $REPOSITORY"
