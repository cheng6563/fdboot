# fdboot

Spring Boot Docker基础镜像
主要功能：
- 设置基础配置环境变量
- 随机端口
- 健康检查脚本

建议设置以下变量
- SPRING_CLOUD_CONFIG_URL
  用于Spring cloud config服务的URL
- JAVA_MEM_OPTS
  设置默认内存设置，默认为 -Xmx500m，
- SERVER_TOMCAT_MAX_THREADS
  Tomcat线程数量，默认为50
- PROFILE
  Spring Boot 的profile名