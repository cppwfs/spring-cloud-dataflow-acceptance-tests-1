#!/usr/bin/env bash

function java_jar() {
    APP_JAVA_PATH=$PWD
    EXPRESSION="nohup ${JAVA_PATH_TO_BIN}java $JAVA_OPTS $MEM_ARGS -jar $APP_JAVA_PATH/scdf-server.jar ${APPLICATION_ARGS} > $APP_JAVA_PATH/scdf-server.log &"
    echo "SPRING_PROFILES_ACTIVE [$SPRING_PROFILES_ACTIVE]"
    echo "executing [$EXPRESSION]"
    eval "${EXPRESSION}"
    pid=$!
    echo ${pid} > ${APP_JAVA_PATH}/app.pid
    echo "[$1] process pid is [$pid]"
    echo "System props are [$2]"
    echo "Logs are under [$APP_JAVA_PATH/scdf-server.log] or from nohup [$APP_JAVA_PATH/nohup.log]"
    . ./server-uri.sh
    return 0
}

run_scripts "$PWD" "config.sh"

APP_LOG_PATH=$PWD/app-logs
rm -rf $APP_LOG_PATH
mkdir $APP_LOG_PATH
APPLICATION_ARGS="$APPLICATION_ARGS --spring.cloud.deployer.local.workingDirectoriesRoot=$APP_LOG_PATH"
download $PWD
java_jar $PWD


