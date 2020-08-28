#!/bin/bash

echo 'Welcome fdboot.'

if [[ -z $START_CLASS ]]; then
    START_CLASS=$(sed -n 's/^Start-Class: //p' ./META-INF/MANIFEST.MF)
    echo "Use start class in ./META-INF/MANIFEST.MF"
fi

if [[ -z $START_CLASS ]]; then
    START_CLASS=$(sed -n 's/^Main-Class: //p' ./META-INF/MANIFEST.MF)
    echo "Use main class in ./META-INF/MANIFEST.MF"
fi

if [[ -z $START_CLASS ]]; then
    echo "Not found start class. please edit ./META-INF/MANIFEST.MF file or set to environment."
    exit 1
fi

START_CLASS=`echo $START_CLASS | tr -d '\r'`
echo "Found start class: ${START_CLASS}."

if [[ -f "application.properties" ]]; then mv application.properties application-d.properties; fi
if [[ -f "application.yml" ]]; then mv application.yml application-d.yml; fi
if [[ -f "application.yaml" ]]; then mv application.yaml application-d.yaml; fi
if [[ -f "application.json" ]]; then mv application.json application-d.json; fi

if [[ -f "application-d.properties" ]]; then PROFILE_D=true; fi
if [[ -f "application-d.yml" ]]; then PROFILE_D=true; fi
if [[ -f "application-d.yaml" ]]; then PROFILE_D=true; fi
if [[ -f "application-d.json" ]]; then PROFILE_D=true; fi


if [[ ! -n "$SPRING_CLOUD_CONFIG_URL" ]]; then
    SPRING_CLOUD_CONFIG_URL=http://localhost:8888
    echo >bootstrap.properties
    echo "No SPRING_CLOUD_CONFIG_URL env, disable spring cloud config."
    echo "# No SPRING_CLOUD_CONFIG_URL env, disable spring cloud config." >>bootstrap.properties
    echo "spring.cloud.config.enabled=false" >>bootstrap.properties
fi


# 读取计算机名
HOSTNAME=$(hostname)

# 获取主要IP
HOST_PRIMARY_IP=$(ip route get 1 | sed -n 's/^.*src \([0-9.]*\) .*$/\1/p')

# 将计算机名写入hosts
echo "127.0.0.1   $HOSTNAME" >>/etc/hosts

# 生成随机端口号
RANDOM_SEED="${START_CLASS}#${APP_NAME}#${HOST_PRIMARY_IP}"

PORT=0
RANDOM_SEED_HEX=`echo -n $RANDOM_SEED | md5sum |  awk '{print $1}'`
RANDOM_SEED_SHORT=${RANDOM_SEED_HEX:0:8}
RANDOM_SEED=`printf "%d\n" 0x${RANDOM_SEED_SHORT}`
read LOWERPORT UPPERPORT </proc/sys/net/ipv4/ip_local_port_range
let RANDOM_DIFF=UPPERPORT-LOWERPORT
RANDOM=$RANDOM_SEED
while :; do
    r=$RANDOM
    let PORT=RANDOM_DIFF%r+LOWERPORT
    # PORT="$(shuf -i $LOWERPORT-$UPPERPORT -n 1)"
    ss -lpn | grep -q ":$PORT " || break
done

#echo "Random port: $PORT"

# 使用环境变量SERVER_PORT中的端口号，如果没有就使用随机的
if [[ -n $SERVER_PORT ]]; then
    APP_PORT=$SERVER_PORT
    echo "Use env port: $APP_PORT"
else
    APP_PORT=$PORT
    echo "Use random port: $APP_PORT"
fi

# 将服务端口号写入文件，用于健康检查
echo $APP_PORT >/app/APP_PORT


#基础参数，通常不会改
if [[ -z "$APP_PARAM_BASE" ]]; then
    # ribbon调用重试
    APP_PARAM_BASE="$APP_PARAM_BASE --ribbon.MaxAutoRetries=1"
    APP_PARAM_BASE="$APP_PARAM_BASE --ribbon.MaxAutoRetriesNextServer=3"
    # eureka刷新
    APP_PARAM_BASE="$APP_PARAM_BASE --eureka.client.registry-fetch-interval-seconds=3"
    APP_PARAM_BASE="$APP_PARAM_BASE --eureka.instance.lease-renewal-interval-in-seconds=5"
    APP_PARAM_BASE="$APP_PARAM_BASE --eureka.instance.lease-expiration-duration-in-seconds=15"
    APP_PARAM_BASE="$APP_PARAM_BASE --ribbon.ServerListRefreshInterval=1000"

    # eureka主动健康检查
    APP_PARAM_BASE="$APP_PARAM_BASE --eureka.client.healthcheck.enabled=true"
    # eureka instance id
    APP_PARAM_BASE="$APP_PARAM_BASE"' --eureka.instance.instance-id=${spring.application.name}#'"${HOST_PRIMARY_IP}#${APP_PORT}"
    # 服务端口号
    APP_PARAM_BASE="$APP_PARAM_BASE --server.port=$APP_PORT"
fi

# 如果没有$PROFILE变量，就设为default，使用默认profile
if [[ -n "$PROFILE" ]]; then
    APP_PARAM_BASE="$APP_PARAM_BASE --spring.profiles.active=$PROFILE"
elif [[ $PROFILE_D ]]; then
    APP_PARAM_BASE="$APP_PARAM_BASE --spring.profiles.active=d"
else
    APP_PARAM_BASE="$APP_PARAM_BASE --spring.profiles.active=default"
fi


# 生成java opts ，拼接运行命令
# -Djava.awt.headless=true 参数设置用软件处理图像，因为虚拟机里没显卡
# -Djava.net.preferIPv4Stack 使用ipv4通信
# -Djava.security.egd=file:/dev/./urandom 使用伪随机数，避免linux熵池不够导致系统阻塞
# -Dspring.cloud.config.uri=$SPRING_CLOUD_CONFIG_URL 应用Spring Cloud Config地址
# -XX:+ExitOnOutOfMemoryError -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/var/log/fdserver/${HOSTNAME}_${APP_PORT}.hprof 使内存溢出时立即停止应用并保存dump
JAVA_OPTS="-Djava.awt.headless=true -Djava.net.preferIPv4Stack=true -Djava.security.egd=file:/dev/./urandom -Dspring.cloud.config.uri=$SPRING_CLOUD_CONFIG_URL -XX:+ExitOnOutOfMemoryError -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/var/log/fdserver/${HOSTNAME}_${APP_PORT}.hprof "
JAVA_CP_OPTS="-cp .:./BOOT-INF/classes:./BOOT-INF/lib/*"
JAVA_CMD="java $JAVA_OPTS $JAVA_MEM_OPTS $JAVA_CP_OPTS $START_CLASS $APP_PARAM_BASE $APP_PARAM"

echo "Java cmd: $JAVA_CMD"
exec $JAVA_CMD
