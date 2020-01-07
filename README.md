# fdboot

Spring Boot Docker基础镜像
主要功能：
- 设置基础配置环境变量
- 随机端口
- 健康检查脚本

将Spring Boot的jar包放到 /app/app.jar

然后建议设置以下变量
- SERVER_PORT  
  服务端口号，默认随机
- SPRING_CLOUD_CONFIG_URL  
  用于Spring cloud config服务的URL
- JAVA_MEM_OPTS  
  设置默认内存设置，默认为 -Xmx500m，
- SERVER_TOMCAT_MAX_THREADS  
  Tomcat线程数量，默认为50
- PROFILE  
  Spring Boot 的profile名

项目将会同步到 https://github.com/leicheng6563/fdboot 随后同步到 https://hub.docker.com/r/leicheng6563/fdboot