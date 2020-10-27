#!/bin/bash

while getopts "u:t:c:" opt; do
  case $opt in
    u)
        url=$OPTARG
        ;;
    t)
        time=$OPTARG
        ;;
    c) 
        content=$OPTARG
        ;;
    \?)
        echo "Invalid option: -$OPTARG" >&2
        exit 1
        ;;
    :)
        echo "Option -$OPTARG requires an argument." >&2
        exit 1
        ;;
  esac
done


if [ ! -n "$url" ];
then
    echo 'Option -u is requires.'
    exit 1
fi


if [ ! -n "$time" ];
then
    echo 'Option -t is requires.'
    exit 1
fi


if [ ! -n "$content" ];
then
    echo 'Option -c is requires.'
    exit 1
fi

startTime=$(date +'%s');

# while [[ "$(curl -s -o /dev/null -w ''%{http_code}'' localhost:9000)" != "200" ]]; do sleep 5; done
while true
do
    rs=$(curl --connect-timeout 1  -m 20 -s "$url");
    if [[ "$rs" == *"$content"* ]]; then
        echo "Success. HTTP result content hit \"$content\". -- $rs";
        exit 0;
    fi
    nowTime=$(date +'%s');
    subTime=$[nowTime-startTime]
    #echo $subTime
    #echo $time
    if [ $subTime -gt $time ]; then
        echo 'Fail. time is out.';
        exit -1;
    fi;
    echo "HTTP result is not match, try again. -- $rs"
    sleep 1;
done

rs=$(curl -s "$url");
echo $rs;