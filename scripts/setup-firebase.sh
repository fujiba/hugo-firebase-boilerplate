#!/bin/bash

if [ $# -lt 1 ]; then
    echo "Usage: $0 project-id"
    exit 1
fi

target=$1
firebase use ${target}

firebase target:apply hosting prod ${target}
firebase target:apply hosting dev dev-${target}

firebase functions:secrets:set BASIC_AUTH_USER
firebase functions:secrets:set BASIC_AUTH_PASSWORD