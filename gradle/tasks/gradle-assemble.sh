#!/bin/bash

set -ex

version=`cat version/number`

cd app

gradle clean assemble

echo "*** In Build ***"

ls -lrt build/libs

#mv build/libs/${APP_NAME}*.jar ../build/${JAR_NAME}-${version}.jar

mv build/libs/app*.jar ../build/${JAR_NAME}-${version}.jar
