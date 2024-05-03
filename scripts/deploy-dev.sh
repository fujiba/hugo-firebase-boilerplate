#!/bin/bash

set eu

SCRIPT_DIR=$(cd $(dirname $0); pwd)
PROJECT_DIR=$(cd $(dirname ${SCRIPT_DIR}); pwd)
DIST_DIR=${PROJECT_DIR}/dist

echo "create web contents..."
(cd ${PROJECT_DIR}/website && hugo)

if [ -e ${DIST_DIR} ]; then
   rm -rf ${DIST_DIR}
fi
mkdir ${DIST_DIR}

echo "deploy hosting..."
firebase deploy --only hosting:dev
echo "deploy functions..."
cp -rp ${PROJECT_DIR}/website/public ${DIST_DIR}
cp -rp functions/* ${DIST_DIR}

(cd ${DIST_DIR} && npm ci)
firebase deploy --only functions

echo "clean up..."
rm -rf ${DIST_DIR}

echo "done!"