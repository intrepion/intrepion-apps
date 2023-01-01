#!/bin/bash

SCRIPT=$0
PASCAL=$1
PROJECT=$2
REPOSITORY=$3
TEMPLATE=$4

echo "Running $SCRIPT $PASCAL $PROJECT $REPOSITORY $TEMPLATE"

pushd .

cd $REPOSITORY

dotnet add ${PROJECT} package Microsoft.AspNet.WebApi.Cors
git add ${PROJECT}
git commit --message "dotnet add ${PROJECT} package Microsoft.AspNet.WebApi.Cors"

FILE=${PROJECT}/Properties/launchSettings.json

SERVER=$(jq '.profiles.http.applicationUrl' $FILE)

FILE=${PROJECT}/Program.cs

# Insert the specified text below the matching line
sed -i '/builder.Services.AddSwaggerGen();/a\
var ClientUrl = Environment.GetEnvironmentVariable("CLIENT_URL") ?? "http://localhost";\
\
var MyAllowSpecificOrigins = "_myAllowSpecificOrigins";\
\
builder.Services.AddCors(options =>\
{\
    options.AddPolicy(MyAllowSpecificOrigins,\
        policy =>\
        {\
            policy.WithOrigins(ClientUrl)\
                .AllowAnyHeader()\
                .AllowAnyMethod();\
        });\
});' $FILE

# Insert the specified text above the matching line
sed -i '/app.Run();/i\
app.UseCors(MyAllowSpecificOrigins);' $FILE

git add $FILE
git commit --message "Added CORS to $PROJECT.";

popd

echo "Completed $SCRIPT $PASCAL $PROJECT $REPOSITORY $TEMPLATE"
