#!/bin/bash

SCRIPT_DIR=$(cd $(dirname $0); pwd)
PROJECT_DIR=$(cd $(dirname ${SCRIPT_DIR}); pwd)
DIST_DIR=${PROJECT_DIR}/dist

PROJECT_ID=$(yq .firebase.projectId ${PROJECT_DIR}/config.yaml)
USE_DEVENV=$(yq .firebase.deployOnCommitDevelop ${PROJECT_DIR}/config.yaml)

target=$PROJECT_ID
firebase use ${PROJECT_ID}

firebase target:apply hosting prod ${PROJECT_ID}

if [ $USE_DEVENV = 'true' ]; then
    echo "setup develop environment"
    firebase target:apply hosting dev dev-${PROJECT_ID}

    firebase functions:secrets:set BASIC_AUTH_USER
    firebase functions:secrets:set BASIC_AUTH_PASSWORD
fi