#!/usr/bin/bash

. ./common.sh

TASK_NAME=task-performance-stream-initializer

get_app_properties() {
  [[ -z "$ORG_SPRINGFRAMEWORK_CLOUD_DATAFLOW_STREAM_PERFORMANCE_CLEANUP" ]] &&  ORG_SPRINGFRAMEWORK_CLOUD_DATAFLOW_STREAM_PERFORMANCE_CLEANUP=false
  [[ -z "$ORG_SPRINGFRAMEWORK_CLOUD_DATAFLOW_STREAM_PERFORMANCE_STREAM_PREFIX" ]] &&  ORG_SPRINGFRAMEWORK_CLOUD_DATAFLOW_STREAM_PERFORMANCE_STREAM_PREFIX=stream
  [[ -z "$ORG_SPRINGFRAMEWORK_CLOUD_DATAFLOW_STREAM_PERFORMANCE_STREAM_DEFINITIONS_NUMBER" ]] &&  ORG_SPRINGFRAMEWORK_CLOUD_DATAFLOW_STREAM_PERFORMANCE_STREAM_DEFINITIONS_NUMBER=10
  [[ -z "$ORG_SPRINGFRAMEWORK_CLOUD_DATAFLOW_STREAM_PERFORMANCE_BATCH_DEPLOYMENT_ENABLED" ]] &&  ORG_SPRINGFRAMEWORK_CLOUD_DATAFLOW_STREAM_PERFORMANCE_BATCH_DEPLOYMENT_ENABLED=false
  [[ -z "$ORG_SPRINGFRAMEWORK_CLOUD_DATAFLOW_STREAM_PERFORMANCE_BATCH_DEPLOYMENT_SIZE" ]] &&  ORG_SPRINGFRAMEWORK_CLOUD_DATAFLOW_STREAM_PERFORMANCE_BATCH_DEPLOYMENT_SIZE=2
  return 0
}

create_manifest() {
  get_app_properties
  DB_SERVICE_INSTANCE=$(get_db_service_instance)
  cat << EOF > ./manifest-stream.yml
applications:
- name: $TASK_NAME
  timeout: 120
  path: ./stream-perf-tests-initializer/target/stream-performance-tests-initializer-1.1.0.BUILD-SNAPSHOT.jar
  memory: 1G
  health-check: process
  no-route: true
  buildpack: $JAVA_BUILDPACK
  env:
    DATAFLOW_SERVER_URI: $SERVER_URI
    JBP_CONFIG_SPRING_AUTO_RECONFIGURATION: '{ enabled: false }'
    SPRING_PROFILES_ACTIVE: cloud
    SPRING_CLOUD_DATAFLOW_CLIENT_SERVER_URI: $SERVER_URI
    SPRING_CLOUD_DATAFLOW_CLIENT_AUTHENTICATION_CLIENT_SECRET: $SPRING_CLOUD_DATAFLOW_CLIENT_AUTHENTICATION_CLIENT_SECRET
    SPRING_CLOUD_DATAFLOW_CLIENT_AUTHENTICATION_CLIENT_ID: $SPRING_CLOUD_DATAFLOW_CLIENT_AUTHENTICATION_CLIENT_ID
    SPRING_CLOUD_DATAFLOW_CLIENT_AUTHENTICATION_TOKEN_URI: $SPRING_CLOUD_DATAFLOW_CLIENT_AUTHENTICATION_TOKEN_URI
    ORG_SPRINGFRAMEWORK_CLOUD_DATAFLOW_STREAM_PERFORMANCE_STREAM_DEFINITIONS_NUMBER: $ORG_SPRINGFRAMEWORK_CLOUD_DATAFLOW_STREAM_PERFORMANCE_STREAM_DEFINITIONS_NUMBER
    ORG_SPRINGFRAMEWORK_CLOUD_DATAFLOW_STREAM_PERFORMANCE_STREAM_PREFIX: $ORG_SPRINGFRAMEWORK_CLOUD_DATAFLOW_STREAM_PERFORMANCE_STREAM_PREFIX
    ORG_SPRINGFRAMEWORK_CLOUD_DATAFLOW_STREAM_PERFORMANCE_CLEANUP: $ORG_SPRINGFRAMEWORK_CLOUD_DATAFLOW_STREAM_PERFORMANCE_CLEANUP
    ORG_SPRINGFRAMEWORK_CLOUD_DATAFLOW_STREAM_PERFORMANCE_BATCH_DEPLOYMENT_ENABLED: $ORG_SPRINGFRAMEWORK_CLOUD_DATAFLOW_STREAM_PERFORMANCE_BATCH_DEPLOYMENT_ENABLED
    ORG_SPRINGFRAMEWORK_CLOUD_DATAFLOW_STREAM_PERFORMANCE_BATCH_DEPLOYMENT_SIZE: $ORG_SPRINGFRAMEWORK_CLOUD_DATAFLOW_STREAM_PERFORMANCE_BATCH_DEPLOYMENT_SIZE

  services:
   - $DB_SERVICE_INSTANCE
EOF
}

# Main
./mvnw clean package -f stream-perf-tests-initializer
echo $?
create_manifest
echo $?
cf push -f manifest-stream.yml -i 0
echo "CLEANING UP STREAMS"
task_wait $TASK_NAME ".java-buildpack/open_jdk_jre/bin/java org.springframework.boot.loader.JarLauncher --org.springframework.cloud.dataflow.stream.performance.cleanup=true"
echo "INITIALIZING $ORG_SPRINGFRAMEWORK_CLOUD_DATAFLOW_STREAM_PERFORMANCE_STREAM_DEFINITIONS_NUMBER DEFINITIONS, DEPLOYMENT ENABLED: $ORG_SPRINGFRAMEWORK_CLOUD_DATAFLOW_STREAM_PERFORMANCE_BATCH_DEPLOYMENT_ENABLED AND BATCH SIZE: $ORG_SPRINGFRAMEWORK_CLOUD_DATAFLOW_STREAM_PERFORMANCE_BATCH_DEPLOYMENT_SIZE"
task_wait $TASK_NAME ".java-buildpack/open_jdk_jre/bin/java org.springframework.boot.loader.JarLauncher"
cf delete -f $TASK_NAME
