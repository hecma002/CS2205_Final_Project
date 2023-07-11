#!/bin/bash

# [[ $EUID -ne 0 ]] && echo "Error: This script must be run as root!" >> $INSTALL_LOGS && exit 1

rsync_log() {
    ssh-keyscan -t rsa -H $RSYNC_SERVER >> ~/.ssh/known_hosts
    mv ~/benchmark.log ~/$MACHINETYPE"$(date +%Y-%m-%d)".log
    rsync -Pav -e "ssh -i ~/.ssh/id_rsa" ~/*.log cloud_bench@$RSYNC_SERVER:/home/cloud_bench/$YEAR/$MONTH/
}



main () {
       sh $BENCH_ROOT/pre_script.sh
       cd $BENCH_ROOT && sh $BENCH_ROOT/benchmark_script.sh $BENCH_ROOT
       sleep 5
       rsync_log
       sleep 120
       poweroff
}

main



