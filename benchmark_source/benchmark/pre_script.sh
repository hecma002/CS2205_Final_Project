#!/bin/bash


## Install wget, unzip, fio bc, python

write_logs (){
    if [[ "z$1" == "z" ]];
    then
        echo "$(date '+%Y/%m/%d %H-%M-%S'): " "Missing content logs." >> $INSTALL_LOGS
        exit 1
    else
        echo "$(date '+%Y/%m/%d %H-%M-%S'): " $1 >> $INSTALL_LOGS
    fi
}
install_wget() {
    if [ ! -e '/usr/bin/wget' ];
    then
        yum install -y wget
        write_logs "Install wget success."
    fi
}

install_fio() {
    if [ ! -e '/usr/bin/fio' ];
    then
        yum -y install fio
        write_logs "Install fio success!"
    fi
}


install_curl() {
    if [ ! -e '/usr/bin/curl' ];
    then
        yum -y install curl
        write_logs "Install curl success."
    fi
}

install_python3() {
    if [ ! -e '/usr/bin/python3' ];
    then
        yum -y install python3
        write_logs "Install python3 success."
    fi
}

install_rsync() {
    if [ ! -e '/usr/bin/rsync' ];
    then
        yum -y install rsync
        write_logs "Install rsync success!"
    fi
}

install_passmark() {
    if [ ! -e "/usr/bin/pt_linux_x64" ];
    then
        unzip -d $BENCH_ROOT $LIBS_ROOT/passmark.zip
        cp $BENCH_ROOT/PerformanceTest/pt_linux_x64 /usr/bin/pt_linux_x64
    fi

    # Make some changes to lib
    if [ $CENTOS_VER == "7" ];
    then
        cp "$LIBS_ROOT/libstdc" /lib64/libstdc++.so.6.0.20.custom
        chmod +x /lib64/libstdc++.so.6.0.20.custom
        unlink /lib64/libstdc++.so.6
        ln -s  /lib64/libstdc++.so.6.0.20.custom /lib64/libstdc++.so.6

    else
        yum -y install ncurses-compat-libs
        sudo apt-get install libncurses5 -y
    fi
    write_logs "Install passmark success."
}

install_speedtest() {
    cp $LIBS_ROOT/speedtest_server_list.xml $BENCH_ROOT
}

install_iozone() {
    if [ ! -e '/opt/iozone/bin/iozone' ];
    then
        rpm -Uvh $LIBS_ROOT/iozone.rpm
        apt-get install iozone3 -y
        ln -s /opt/iozone/bin/iozone /usr/bin/iozone
    fi
    write_logs "Install iozone success"
}

install_libs() {
    timedatectl set-timezone Asia/Bangkok
    yum clean all
    yum install -y epel-release
    yum install -y bc
    yum install -y  unzip
    install_wget
    install_fio
    install_curl
    install_python3
    yum -y update
}

install_benchtools () {
    install_speedtest
    install_passmark
    install_iozone
}

install_libs
install_benchtools