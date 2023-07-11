#!/bin/bash

[[ "z$1" == "z" ]] && echo -e "Error: Enter directory path to test disk performance! Ex: ./benchmark_script.sh /example/dir/path." && exit 1


next() {
	printf "%-70s\n" "-" | sed 's/\s/-/g'
}

speed_test() {
	if [ -e '/bin/python3' ] || [ -e '/usr/bin/python3' ];
	then
		local tmp_1=`mktemp` || exit 1
		local speedtest="/bin/python3"

		$speedtest speedtest.py --json --server $1 --secure > $tmp_1 2>&1
		download_speed=$(sed "s/^.*\(\"download\":\) \([[:digit:]]\+.[[:digit:]]\+\).*/\2/" $tmp_1)
		download_speed_mbps=$(echo "scale=0;$download_speed/1000000" | bc -l)
		upload_speed=$(sed "s/^.*\(\"upload\":\) \([[:digit:]]\+.[[:digit:]]\+\).*/\2/" $tmp_1)
		upload_speed_mbps=$(echo "scale=0;$upload_speed/1000000" | bc -l)
		latency_speed=$(sed "s/^.*\(\"latency\":\) \([[:digit:]]\+.[[:digit:]]\+\).*/\2/" $tmp_1 | cut -d "." -f 1)
		server=$(sed "s/^.*\(\"country\":\) \"\(.*\)\", \"cc\".*\(\"sponsor\":\) \"\(.*\)\", \"id\".*$/\2 - \4/" $tmp_1)
		echo "network_benchmark|$server|$upload_speed_mbps|$download_speed_mbps|$latency_speed"

		rm -rf $tmp_1
	else
		echo "Speedtest-cli is missing!!! Please install speedtest-cli before running test." >> $INSTALL_LOGS
	fi
}

test_network() {
	# Reference source: https://linuxspeedtest.com/
	# VietNam - VNPT-NET 6106, Viettel Network 26853
	# Thailand - 3BB 24507, AIS Fibre 40955
	# Indonesia - PT. Aplikanusa Lintasarta 30838, Telkomsel 43255
	# Phillip - IntegraNet 18416, Smart Communications Inc 7428
	# Singapore - M1 Limited 7311, StarHub Mobile Pte Ltd 4235
	# Malaysia - Celcom 4956, IX Telecom 13176

	declare -a my_array=(6106 26853 24507 40955 30838 43255 18416 7428 7311 4235 4956 13176)
	length=${#my_array[@]}
	for (( i=0; i < ${length}; i++ ));
	do
		delayer=$((( RANDOM % 90 )+30))
		sleep $delayer
		speed_test ${my_array[$i]}
	done
}

test_disk() {
	# Khanh
	if [ -e '/usr/bin/fio' ];
	then
		local tmp_1=$(mktemp)
		local tmp_2=$(mktemp)
		local tmp_3=$(mktemp)
		local tmp_4=$(mktemp)
		local test_dir="$(echo $1 | sed 's:/*$::')/test_disk"
		mkdir -p $test_dir > /dev/null 2>&1
		sudo fio --name=write_throughput --directory=$test_dir --numjobs=8 --size=4G --time_based --runtime=60s --ramp_time=2s --ioengine=libaio --direct=1 --verify=0 --bs=1M --iodepth=64 --rw=write --group_reporting=1 --output="$tmp_1"
		if [ $(fio -v | cut -d '.' -f 1) == "fio-2" ]; then
			local seq_iops_write=`grep "iops=" "$tmp_1" | grep write | awk -F[=,]+ '{print $6}'`
			local seq_bw_write=`grep "bw=" "$tmp_1" | grep write | awk -F[=,B]+ '{if(match($4, /[0-9]+K$/)) {printf("%.1f", int($4)/1024);} else if(match($4, /[0-9]+M$/)) {printf("%.1f", substr($4, 0, length($4)-1))} else {printf("%.1f", int($4)/1024/1024);}}'`""
		elif [ $(fio -v | cut -d '.' -f 1) == "fio-3" ]; then
			local seq_iops_write=`grep "IOPS=" "$tmp_1" | grep write | awk -F[=,]+ '{print $2}'`
			local seq_bw_write=`grep "bw=" "$tmp_1" | grep WRITE | awk -F[\(\)] '{print $2}' | sed "s/\([[:digit:]]\+\)\(MB\/s\)$/\1/"`
		fi
		rm -rf $test_dir/*
		sudo fio --name=write_iops --directory=$test_dir --size=4G --time_based --runtime=60s --ramp_time=2s --ioengine=libaio --direct=1 --verify=0 --bs=4K --iodepth=64 --rw=randwrite --group_reporting=1 --output="$tmp_2"
		if [ $(fio -v | cut -d '.' -f 1) == "fio-2" ]; then
			local rand_iops_write=`grep "iops=" "$tmp_2" | grep write | awk -F[=,]+ '{print $6}'`
			local rand_bw_write=`grep "bw=" "$tmp_2" | grep write | awk -F[=,B]+ '{if(match($4, /[0-9]+K$/)) {printf("%.1f", int($4)/1024);} else if(match($4, /[0-9]+M$/)) {printf("%.1f", substr($4, 0, length($4)-1))} else {printf("%.1f", int($4)/1024/1024);}}'`""
		elif [ $(fio -v | cut -d '.' -f 1) == "fio-3" ]; then
			local rand_iops_write=`grep "IOPS=" "$tmp_2" | grep write | awk -F[=,]+ '{print $2}'`
			local rand_bw_write=`grep "bw=" "$tmp_2" | grep WRITE | awk -F[\(\)] '{print $2}' | sed "s/\([[:digit:]]\+\)\(MB\/s\)$/\1/"`
		fi
		rm -rf $test_dir/*
		sudo fio --name=read_throughput --directory=$test_dir --numjobs=8 --size=4G --time_based --runtime=60s --ramp_time=2s --ioengine=libaio --direct=1 --verify=0 --bs=1M --iodepth=64 --rw=read --group_reporting=1 --output="$tmp_3"
		if [ $(fio -v | cut -d '.' -f 1) == "fio-2" ]; then
			local seq_iops_read=`grep "iops=" "$tmp_3" | grep read | awk -F[=,]+ '{print $6}'`
			local seq_bw_read=`grep "bw=" "$tmp_3" | grep read | awk -F[=,B]+ '{if(match($4, /[0-9]+K$/)) {printf("%.1f", int($4)/1024);} else if(match($4, /[0-9]+M$/)) {printf("%.1f", substr($4, 0, length($4)-1))} else {printf("%.1f", int($4)/1024/1024);}}'`""			
		elif [ $(fio -v | cut -d '.' -f 1) == "fio-3" ]; then
			local seq_iops_read=`grep "IOPS=" "$tmp_3" | grep read | awk -F[=,]+ '{print $2}'`
			local seq_bw_read=`grep "bw=" "$tmp_3" | grep READ | awk -F[\(\)] '{print $2}' | sed "s/\([[:digit:]]\+\)\(MB\/s\)$/\1/"`
		fi
		rm -rf $test_dir/*
		sudo fio --name=read_iops --directory=$test_dir --size=4G --time_based --runtime=60s --ramp_time=2s --ioengine=libaio --direct=1 --verify=0 --bs=4K --iodepth=64 --rw=randread --group_reporting=1 --output="$tmp_4"
		if [ $(fio -v | cut -d '.' -f 1) == "fio-2" ]; then
			local rand_iops_read=`grep "iops=" "$tmp_4" | grep read | awk -F[=,]+ '{print $6}'`
			local rand_bw_read=`grep "bw=" "$tmp_4" | grep read | awk -F[=,B]+ '{if(match($4, /[0-9]+K$/)) {printf("%.1f", int($4)/1024);} else if(match($4, /[0-9]+M$/)) {printf("%.1f", substr($4, 0, length($4)-1))} else {printf("%.1f", int($4)/1024/1024);}}'`""			
		elif [ $(fio -v | cut -d '.' -f 1) == "fio-3" ]; then
			local rand_iops_read=`grep "IOPS=" "$tmp_4" | grep read | awk -F[=,]+ '{print $2}'`
			local rand_bw_read=`grep "bw=" "$tmp_4" | grep READ | awk -F[\(\)] '{print $2}' | sed "s/\([[:digit:]]\+\)\(MB\/s\)$/\1/"`
		fi
		rm -rf $test_dir/*
		echo -e "disk_benchmark|Random read performance|$rand_iops_read|$rand_bw_read"
		echo -e "disk_benchmark|Random write performance|$rand_iops_write|$rand_bw_write"
		echo -e "disk_benchmark|Sequential read perfomance|$seq_iops_read|$seq_bw_read"
		echo -e "disk_benchmark|Sequential write performance|$seq_iops_write|$seq_bw_write"
		# Cleanup temp files
		rm -rf $tmp_1 $tmp_2 $tmp_3 $tmp_4 $test_dir
	else
		echo "Fio is missing!!! Please install Fio before running test."
	fi
}

test_cpu() {
	# Khanh
	if [ -e '/usr/bin/pt_linux_x64' ]; then
		result_filename="$(pwd)/results_cpu.yml"
		cpu_cores=$(lscpu | egrep '^CPU\(s\).*' | sed "s/.*\([[:digit:]]\+\)/\1/")
		export TERM=xterm
		pt_linux_x64 -p $cpu_cores -i 1 -d 2 -r 1 > /dev/null
		local cpu_mark=`grep "SUMM_CPU:" "$result_filename"| cut -d ":" -f 2 | awk '{printf("%.0f", $1)}'`
		local cpu_integer_math=`grep "CPU_INTEGER_MATH:" "$result_filename"| cut -d ":" -f 2 | awk '{printf("%.0f", $1)}'`
		local cpu_floatingpoint_math=`grep "CPU_FLOATINGPOINT_MATH:" "$result_filename"| cut -d ":" -f 2 | awk '{printf("%.0f", $1)}'`
		local cpu_sorting=`grep "CPU_SORTING:" "$result_filename"| cut -d ":" -f 2 | awk '{printf("%.0f", $1)}'`
		local cpu_prime=`grep "CPU_PRIME:" "$result_filename"| cut -d ":" -f 2 | awk '{printf("%.0f", $1)}'`
		local cpu_encryption=`grep "CPU_ENCRYPTION:" "$result_filename"| cut -d ":" -f 2 | awk '{printf("%.0f", $1)}'`
		local cpu_compression=`grep "CPU_COMPRESSION:" "$result_filename"| cut -d ":" -f 2 | awk '{printf("%.0f", $1)}'`
		local cpu_sse=`grep "CPU_sse:" "$result_filename"| cut -d ":" -f 2 | awk '{printf("%.0f", $1)}'`
		local cpu_singlethreaded=`grep "CPU_SINGLETHREAD:" "$result_filename"| cut -d ":" -f 2 | awk '{printf("%.0f", $1)}'`
		echo "cpu_benchmark|CPU Mark|$cpu_mark"
		echo "cpu_benchmark|Integer Math|$cpu_integer_math"
		echo "cpu_benchmark|Floating Point Math|$cpu_floatingpoint_math"
		echo "cpu_benchmark|Prime Numbers|$cpu_prime"
		echo "cpu_benchmark|Sorting|$cpu_sorting"
		echo "cpu_benchmark|Encryption|$cpu_encryption"
		echo "cpu_benchmark|Compression|$cpu_compression"
		echo "cpu_benchmark|CPU Single Threaded|$cpu_singlethreaded"
		echo "cpu_benchmark|Extended Instructions(SSE)|$cpu_sse"
		# rm -rf "$result_filename"
	else
		echo "Passmark is missing!!! Please install Passmark before running test." | tee /root/no_cpu.txt
	fi
}
test_memory() {  
	# Tuong 
	if [ -e '/usr/bin/pt_linux_x64' ]; then
		result_filename="$(pwd)/results_memory.yml"
		cpu_cores=$(lscpu | egrep '^CPU\(s\).*' | sed "s/.*\([[:digit:]]\+\)/\1/")
		export TERM=xterm
		pt_linux_x64 -p $cpu_cores -i 1 -d 2 -r 2 > /dev/null
		local memory_db_operation=`grep "ME_ALLOC_S:" "$result_filename"| cut -d ":" -f 2 | awk '{printf("%.0f", $1)}'`
		local memory_read_cached=`grep "ME_READ_S:" "$result_filename"| cut -d ":" -f 2 | awk '{printf("%.0f", $1)}'`
		local memory_read_uncached=`grep "ME_READ_L:" "$result_filename"| cut -d ":" -f 2 | awk '{printf("%.0f", $1)}'`
		local memory_write=`grep "ME_WRITE:" "$result_filename"| cut -d ":" -f 2 | awk '{printf("%.0f", $1)}'`
		local memory_available_ram=`grep "ME_LARGE:" "$result_filename"| cut -d ":" -f 2 | awk '{printf("%.0f", $1)}'`
		local memory_latency=`grep "ME_LATENCY:" "$result_filename"| cut -d ":" -f 2 | awk '{printf("%.0f", $1)}'`
		local memory_threaded=`grep "ME_THREADED:" "$result_filename"| cut -d ":" -f 2 | awk '{printf("%.0f", $1)}'`
		echo "memory_benchmark|Database Operations|$memory_db_operation"
		echo "memory_benchmark|Memory Read Cached|$memory_read_cached"
		echo "memory_benchmark|Memory Read Uncached|$memory_read_uncached"
		echo "memory_benchmark|Memory Write|$memory_write"
		echo "memory_benchmark|Available RAM|$memory_available_ram"
		echo "memory_benchmark|Memory Latency|$memory_latency"
		echo "memory_benchmark|Memory Threaded|$memory_threaded"
		rm -rf $result_filename
	else
		echo "Passmark is missing!!! Please install Passmark before running test." | tee /root/no_mem.txt
	fi
}
test_filesystem() {
	# Son
	if [ -e '/usr/bin/iozone' ]; then
		local TEST_FILE_SIZE=524288 #512MB. file size temporary iozone using to test, recommend x3 size of memmory. Reference https://www.thegeekstuff.com/2011/05/iozone-examples/
		local TEST_RECORD_SIZE=8192 #8M. It depend of DB block size. IOZone using record size ranging from 4K to 16MB
		local name_output_file="/tmp/$(date +%Y-%m-%d_%H-%M-%S).iozone"
		local test_dir="$(echo $1 | sed 's:/*$::')"
		mkdir -p $test_dir > /dev/null 2>&1
		echo "$(iozone -s $TEST_FILE_SIZE -r $TEST_RECORD_SIZE -i 0 -i 1 -i 2 -f $test_dir/tmp_file)" > "$name_output_file"
		local initial_write=`grep $TEST_FILE_SIZE "$name_output_file" | grep $TEST_RECORD_SIZE | grep -v "iozone" | awk '{printf($3)}'`
		local rewrite=`grep $TEST_FILE_SIZE "$name_output_file" | grep $TEST_RECORD_SIZE | grep -v "iozone" | awk '{printf($4)}'`
		local read=`grep $TEST_FILE_SIZE "$name_output_file" | grep $TEST_RECORD_SIZE | grep -v "iozone" | awk '{printf($5)}'`
		local re_read=`grep $TEST_FILE_SIZE "$name_output_file" | grep $TEST_RECORD_SIZE | grep -v "iozone" | awk '{printf($6)}'`
		local rand_read=`grep $TEST_FILE_SIZE "$name_output_file" | grep $TEST_RECORD_SIZE | grep -v "iozone" | awk '{printf($7)}'`
		local rand_write=`grep $TEST_FILE_SIZE "$name_output_file" | grep $TEST_RECORD_SIZE | grep -v "iozone" | awk '{printf($8)}'`
		printf "filesystem_benchmark|Write performance|${initial_write}\n"
		printf "filesystem_benchmark|Re-write performance|${rewrite}\n"
		printf "filesystem_benchmark|Read performance|${read}\n"
		printf "filesystem_benchmark|Re_read performance|${re_read}\n"
		printf "filesystem_benchmark|Random-write performance|${rand_write}\n"
		printf "filesystem_benchmark|Random-read performance|${rand_read}\n"
        	rm -rf "$test_dir/tmp_file"
		rm -f $name_output_file #remove log file
	else
		echo "IOZone is missing!!! Please install IOZone before running test."
	fi
}
test() {
	date=$( date )
	echo "Start Benchmark_$(date +%Y-%m-%d_%H:%M:%S)"
	echo "OS: $(rpm -q centos-release)"
	next
	test_cpu && next
	test_memory && next
	test_filesystem $1 && next
	test_disk $1 && next
	test_network && next
	date=$( date )
	echo "Finished Benchmark_$(date +%Y-%m-%d_%H:%M:%S)"
}
clear
tmp=$(mktemp)
test $1 | tee $tmp
cat $tmp >> ~/benchmark.log
rm -rf $tmp