#!/bin/sh

#### 
#  The following variables must be set in the build.rc file before executing this script
####
#ARTIFACT_URL=
#ARTIFACT_STREAM=

#DOCKER_EMAIL=
#DOCKER_USERNAME=
#DOCKER_PASSWORD=

source ./build.rc

####
# UCD_VERSION will be read from the stream file on the artifact server so no need to set it
####
UCD_ENG_VERSION=

curl -O "$ARTIFACT_URL/urbancode/ibm-ucd-patterns-engine/$ARTIFACT_STREAM.txt"
UCD_ENG_VERSION=`cat $ARTIFACT_STREAM.txt`  # i.e. latest or dev or qa or vnext etc... file will contain just the version number
rm -f $ARTIFACT_STREAM.txt

rm -rf artifacts/*
curl -O "$ARTIFACT_URL/urbancode/ibm-ucd-patterns-engine/$UCD_ENG_VERSION/ibm-ucd-patterns-engine.tgz"
tar xvzf ibm-ucd-patterns-engine.tgz -C artifacts/
rm -f ibm-ucd-patterns-engine.tgz

docker login -e="$DOCKER_EMAIL" -u="$DOCKER_USERNAME" -p="$DOCKER_PASSWORD"
docker build -t stackinabox/urbancode-patterns-engine:$UCD_ENG_VERSION .
docker push stackinabox/urbancode-patterns-engine:$UCD_ENG_VERSION
