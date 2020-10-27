#! /bin/bash
# 健康检查脚本
PORT=$(cat /app/APP_PORT)
if [[ -z $PORT ]]; then
    echo "Error: miss app port file."
    exit 0
fi
# 调用服务的/health接口，在100秒内返回了 "status":"UP" 字样就代表成功。
./wait-http.sh -u "http://localhost:$PORT/health" -t 100 -c '"status":"UP"'