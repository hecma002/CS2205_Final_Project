#!/bin/bash

YEAR=`date -d "$date" +%Y`
MONTH=`date -d "$date" +%m`
SOURCE_DIR="/opt/benchmark_cloud/insert_log"
LOGS_DIR="/home/cloud_bench/$YEAR/$MONTH"

insert_log() {
    rm -rf $LOGS_DIR/parselog.py
    list_instance=`ls $LOGS_DIR`
    cp $SOURCE_DIR/parselog.py $LOGS_DIR/parselog.py
    for i in $list_instance
    do
        logs="$(cd $LOGS_DIR && python3 parselog.py $i)"
        echo "$(date '+%Y-%m-%d %H-%M-%S'): $logs" >> /var/log/benchmark/insert_"$YEAR$MONTH"
        sleep 5
    done
}
main() {
    touch /var/log/benchmark/insert_"$YEAR$MONTH"
    insert_log
}

main
