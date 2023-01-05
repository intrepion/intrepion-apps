#!/bin/bash

SCRIPT=$0
KEBOB=$1
PASCAL=$2
PROJECT=$3
REPOSITORY=$4
TEMPLATE=$5

echo " - Running $SCRIPT $KEBOB $PASCAL $PROJECT $REPOSITORY $TEMPLATE"

if [ $# -ne 5 ]; then
  echo "usage: $SCRIPT <KEBOB> <PASCAL> <PROJECT> <REPOSITORY> <TEMPLATE>"
  exit 1
fi

pushd .

cd $REPOSITORY
pwd

dotnet add ${PROJECT} package Npgsql.EntityFrameworkCore.PostgreSQL
git add ${PROJECT}
git commit --message "dotnet add ${PROJECT} package Npgsql.EntityFrameworkCore.PostgreSQL"

mkdir -p scripts

FILE=scripts/init_postgres.sh

cat > $FILE << EOF
#!/usr/bin/env bash

set -x
set -eo pipefail

if ! [ -x "$(command -v psql)" ]; then
    echo >&2 "Error: psql is not installed."
    exit 1
fi

DB_USER=\${POSTGRES_USER:=postgres}
DB_PASSWORD="\${POSTGRES_PASSWORD:=password}"
DB_NAME="\${POSTGRES_DB:=intrepion}"
DB_PORT="\${POSTGRES_PORT:=5432}"

if [[ -z "\${SKIP_DOCKER}" ]]
then
    sudo docker run\\
        -e POSTGRES_USER=\${DB_USER}\\
        -e POSTGRES_PASSWORD=\${DB_PASSWORD}\\
        -e POSTGRES_DB=\${DB_NAME}\\
        -p "\${DB_PORT}":5432\\
        -d postgres\\
        postgres -N 1000
fi

export PGPASSWORD="\${DB_PASSWORD}"
until psql -h "localhost" -U "\${DB_USER}" -p "\${DB_PORT}" -d "postgres" -c '\q'; do
    >&2 echo "Postgres is still unavailable - sleeping"
    sleep 1
done

>&2 echo "Postgres is up and running on port \${DB_PORT}"

DATABASE_URL=postgres://\${DB_USER}:\${DB_PASSWORD}@localhost:\${DB_PORT}/\${DB_NAME}
export DATABASE_URL
EOF

chmod +x $FILE
git add $FILE
git commit --message "Added init postgres script."

popd

echo " - Completed $SCRIPT $KEBOB $PASCAL $PROJECT $REPOSITORY $TEMPLATE"
