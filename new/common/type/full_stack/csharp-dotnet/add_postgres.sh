#!/bin/bash

SCRIPT=$0
PASCAL=$1
PROJECT=$2
REPOSITORY=$3
TEMPLATE=$4

echo "Running $SCRIPT $PASCAL $PROJECT $REPOSITORY $TEMPLATE"

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

>&2 echo "Postgres is up and running on port \${DB_PORT} - running migrations now!"

DATABASE_URL=postgres://\${DB_USER}:\${DB_PASSWORD}@localhost:\${DB_PORT}/\${DB_NAME}
export DATABASE_URL
EOF

chmod +x $FILE
git add $FILE
git commit --message "Added init postgres script."

FILE=${PROJECT}/appsettings.Development.json

cat > $FILE << EOF
{
  "ConnectionStrings": {  
    "DefaultConnection": "Host=localhost;Database=intrepion;Username=postgres;Password=password"
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  }
}
EOF

git add $FILE
git commit --message "Updated appsettings.Development file."

FILE=${PROJECT}/Properties/launchSettings.json

SERVER=$(jq '.profiles.http.applicationUrl' $FILE)

FILE=${PROJECT}/Program.cs

cat > $FILE << EOF
var builder = WebApplication.CreateBuilder(args);

// Add services to the container.

builder.Services.AddControllers();
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var ClientUrl = Environment.GetEnvironmentVariable("CLIENT_URL") ?? $SERVER;

var MyAllowSpecificOrigins = "_myAllowSpecificOrigins";

builder.Services.AddCors(options =>
{
    options.AddPolicy(MyAllowSpecificOrigins,
        policy =>
        {
            policy.WithOrigins(ClientUrl)
                .AllowAnyHeader()
                .AllowAnyMethod();
        });
});

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

app.UseAuthorization();

app.MapControllers();

app.UseCors(MyAllowSpecificOrigins);

app.Run();

public partial class Program {}
EOF

git add $FILE
git commit --message "Updated Program class."

popd

echo "Completed $SCRIPT $PASCAL $PROJECT $REPOSITORY $TEMPLATE"
