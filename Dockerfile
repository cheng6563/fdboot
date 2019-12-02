FROM openjdk:8-jdk

ENV LC=Asia/Shanghai \
        LANG=zh_CN.UTF-8 \
        SERVER_TOMCAT_MAX_THREADS=100 \
        EUREKA_INSTANCE_PREFER_IP_ADDRESS=true

RUN sed -i 's/deb\.debian\.org/mirrors\.aliyun\.com/g' /etc/apt/sources.list &&\
    sed -i 's/security\.debian\.org/mirrors\.aliyun\.com/g' /etc/apt/sources.list &&\
    apt-get update &&\
    apt-get install -y curl lrzsz vim

WORKDIR /app

COPY ./* ./boot

VOLUME /var/log/fdserver

ENTRYPOINT [ "boot.sh" ]

HEALTHCHECK --interval=30s --timeout=105s --start-period=20s --retries=3 CMD [ "health-check.sh" ]