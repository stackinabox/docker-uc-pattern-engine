#!/usr/bin/env sh

#### 
#  The following variables must be set in the build.rc file before executing this script
####
ARTIFACT_URL=${ARTIFACT_URL:-http://artifactory.stackinabox.io/artifactory}
#ARTIFACT_STREAM=

#DOCKER_EMAIL=
#DOCKER_USERNAME=
#DOCKER_PASSWORD=

source ./build.rc

####
# UCD_VERSION will be read from the stream file on the artifact server so no need to set it
####
UCD_ENG_VERSION=${UCD_ENG_VERSION:-latest}
UCD_ENG_DOWNLOAD_URL="$ARTIFACT_URL/urbancode-snapshot-local/urbancode/ibm-ucd-patterns-engine/$UCD_ENG_VERSION/ibm-ucd-patterns-engine.tgz"

rm -rf artifacts/*

echo "artifact url: $ARTIFACT_URL"
echo "ucd version:  $UCD_ENG_VERSION"
echo "ucd download url: $UCD_ENG_DOWNLOAD_URL"

curl -O UCD_ENG_DOWNLOAD_URL
tar xvzf ibm-ucd-patterns-engine.tgz -C artifacts/
rm -f ibm-ucd-patterns-engine.tgz

docker login -e="$DOCKER_EMAIL" -u="$DOCKER_USERNAME" -p="$DOCKER_PASSWORD"
docker build -t stackinabox/urbancode-patterns-engine:$UCD_ENG_VERSION .
docker push stackinabox/urbancode-patterns-engine:$UCD_ENG_VERSION
