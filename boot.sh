#!/bin/bash

echo 'Welcome fdboot.'

if  [ ! -n '/app/app.jar' ]; then
    echo 'No exist /app/app.jar, exit.'
    return -1
fi

if [[ ! -n "$SPRING_CLOUD_CONFIG_URL" ]]; then
    SPRING_CLOUD_CONFIG_URL="http://127.0.0.1:8888"
fi


read LOWERPORT UPPERPORT < /proc/sys/net/ipv4/ip_local_port_range
while :
do
        PORT="`shuf -i $LOWERPORT-$UPPERPORT -n 1`"
        ss -lpn | grep -q ":$PORT " || break
done

#echo "Random port: $PORT"
if [[ -z $SERVER_PORT ]]; then
	APP_PORT=$SERVER_PORT
	echo "Use env port: $APP_PORT"
else
	APP_PORT=$PORT
	echo "Use random port: $APP_PORT"
fi

echo $APP_PORT>/app/APP_PORT

HOSTNAME=$(hostname)

#基础参数，通常不会改
if [[  -n "$APP_PARAM_BASE" ]]; then
    APP_PARAM_BASE="$APP_PARAM_BASE --ribbon.MaxAutoRetries=1"
    APP_PARAM_BASE="$APP_PARAM_BASE --ribbon.MaxAutoRetriesNextServer=3"
    APP_PARAM_BASE="$APP_PARAM_BASE --eureka.client.registry-fetch-interval-seconds=3"
    APP_PARAM_BASE="$APP_PARAM_BASE --eureka.instance.lease-renewal-interval-in-seconds=3"
    APP_PARAM_BASE="$APP_PARAM_BASE --ribbon.ServerListRefreshInterval=1000"
    APP_PARAM_BASE="$APP_PARAM_BASE"' --eureka.instance.instance-id=${spring.application.name}_'"${HOSTNAME}_${APP_PORT}"
    APP_PARAM_BASE="$APP_PARAM_BASE --server.port=$APP_PORT"
fi

if [[ -n "$PROFILE" ]]; then
    APP_PARAM_BASE="$APP_PARAM_BASE --spring.profiles.active=$PROFILE"
fi

JAVA_OPTS="-Djava.awt.headless=true -Djava.net.preferIPv4Stack=true -Djava.security.egd=file:/dev/./urandom -Dspring.cloud.config.uri=$SPRING_CLOUD_CONFIG_URL -XX:+CrashOnOutOfMemoryError -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/app/heap-dump.hprof "
JAVA_CMD="java $JAVA_OPTS $JAVA_MEM_OPTS  -jar /app/app.jar $APP_PARAM_BASE $APP_PARAM"

echo "Java cmd: $JAVA_CMD"
$JAVA_CMD
