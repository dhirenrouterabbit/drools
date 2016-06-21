#!/usr/bin/env bash

# If not server identifier set via docker env variable, use the container's hostname as server id.
if [ ! -n "$KIE_SERVER_ID" ]; then
    export KIE_SERVER_ID=kie-server-$HOSTNAME
fi
echo "Using '$KIE_SERVER_ID' as KIE server identifier"

# If this KIE execution server container is linked with some KIE Workbench container, the following environemnt variables will be present, so configure the application arguments based on their values.
if [ -n "$KIE_WB_PORT_8080_TCP" ] &&  [ -n "$KIE_WB_ENV_KIE_CONTEXT_PATH" ] &&  [ -n "$KIE_WB_PORT_8080_TCP_ADDR" ]; then
    # Obtain current container's IP address.
    #DOCKER_IP=$(ip addr show eth0 | grep -E '^\s*inet' | grep -m1 global | awk '{ print $2 }' | sed 's|/.*||')
    DOCKER_IP="ec2-52-64-146-119.ap-southeast-2.compute.amazonaws.com"
    # KIE Workbench environment variables are set. Proceed with automatic configuration.
    echo "Detected successfull KIE Workbench container linked. Applying automatic configuration for the linked containers..."
    export KIE_SERVER_LOCATION="http://$DOCKER_IP:8180/$KIE_CONTEXT_PATH/services/rest/server"
    export KIE_SERVER_CONTROLLER="http://$DOCKER_IP:8080/$KIE_WB_ENV_KIE_CONTEXT_PATH/rest/controller"
    export KIE_MAVEN_REPO="http://$DOCKER_IP:8080/$KIE_WB_ENV_KIE_CONTEXT_PATH/maven2"
fi

# Default arguments for running the KIE Execution server.
JBOSS_ARGUMENTS=" -b $JBOSS_BIND_ADDRESS -Dorg.kie.server.id=\"$KIE_SERVER_ID\" -Dorg.kie.server.user=\"$KIE_SERVER_USER\" -Dorg.kie.server.pwd=\"$KIE_SERVER_PWD\" -Dorg.kie.server.location=\"$KIE_SERVER_LOCATION\" "
echo "Using '$KIE_SERVER_LOCATION' as KIE server location"

# Controller argument for the KIE Execution server. Only enabled if set the environment variable/s or detected container linking.
if [ -n "$KIE_SERVER_CONTROLLER" ]; then
    echo "Using '$KIE_SERVER_CONTROLLER' as KIE server controller"
    echo "Using '$KIE_MAVEN_REPO' for the kie-workbench Maven repository URL"
    JBOSS_ARGUMENTS="$JBOSS_ARGUMENTS -Dorg.kie.server.controller=\"$KIE_SERVER_CONTROLLER\" -Dorg.kie.server.controller.user=\"$KIE_SERVER_CONTROLLER_USER\" -Dorg.kie.server.controller.pwd=\"$KIE_SERVER_CONTROLLER_PWD\" "
fi

# Start Wildfly with the given arguments.
echo "Running KIE Execution Server on JBoss Wildfly..."
exec ./standalone.sh $JBOSS_ARGUMENTS -c standalone-full-kie-server.xml
exit $?
