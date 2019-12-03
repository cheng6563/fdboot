FROM openjdk:8-jdk


RUN sed -i 's/deb\.debian\.org/mirrors\.aliyun\.com/g' /etc/apt/sources.list &&\
    sed -i 's/security\.debian\.org/mirrors\.aliyun\.com/g' /etc/apt/sources.list &&\
    apt-get update &&\
    apt-get install -y curl lrzsz vim telnet locales &&\
    sed -i '/^#.* zh_CN.UTF-8 /s/^#//' /etc/locale.gen &&\
    locale-gen &&\
    cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

ENV LC=Asia/Shanghai \
        SERVER_TOMCAT_MAX_THREADS=100 \
        EUREKA_INSTANCE_PREFER_IP_ADDRESS=true \
        JAVA_MEM_OPTS="-Xmx500m" \
        LANG=zh_CN.UTF-8 


WORKDIR /app

COPY ./* ./

VOLUME /var/log/fdserver

CMD [ "./boot.sh" ]

HEALTHCHECK --interval=2s --timeout=60s --start-period=10s --retries=3 CMD [ "./health-check.sh" ]
