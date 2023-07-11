#!/usr/bin/env bash

export TERM=xterm

export ROOT="/tmp/benchmark"
export AWS_ROOT=$ROOT/aws
export GCP_ROOT=$ROOT/gcp
export BENCH_ROOT=$ROOT/benchmark
export LIBS_ROOT=$BENCH_ROOT/libs

export INSTALL_LOGS=$ROOT/install.log
export RSYNC_SERVER="RSYNC_SERVER_IP"

export MACHINETYPE=`cat /tmp/machinetype`
export YEAR=`date -d "$date" +%Y`
export MONTH=`date -d "$date" +%m`
export DAY=`date -d "$date" +%d`
export CENTOS_VER="`cat /etc/redhat-release | cut -d " " -f 4 | awk -F[.] '{print $1}'`"

cd $ROOT/ && sh $ROOT/start_bench.sh

