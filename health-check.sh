#! /bin/bash
PORT=$(cat /app/APP_PORT)
if [[ -n $PORT ]]; then
    echo "Error: miss app port file."
    return 0
fi
./wait-http.sh -u "http://localhost:$PORT/health" -t 100 -c '"status":"UP"'