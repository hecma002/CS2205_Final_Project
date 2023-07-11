import sys
import linecache
import mysql.connector
from mysql.connector import Error

#var
log_file_name = sys.argv[1]
cloud_code = "null"
instance_type = "null"
date_time = ""

#mysql
HOSTNAME = 'localhost'
DATABASE = 'grafana'
USER = 'grafana'
PASSWORD = 'qc4dvYh9&N*UTss'


def sql_query(query):
    print(query)
    try:
        connection = mysql.connector.connect(host=HOSTNAME,database=DATABASE,user=USER,password=PASSWORD)
        if connection.is_connected():
            db_Info = connection.get_server_info()
            cursor = connection.cursor()
            cursor.execute(query)
            connection.commit()
            print(cursor.rowcount, " success record inserted.")
            cursor.close()
            connection.close()
    except Error as e:
        print("Error while connecting to MySQL", e)

def get_instance_info():
    container = log_file_name.split('_')
    global cloud_code
    global instance_type
    global date_time
    cloud_code = container[0]
    instance_type = container[1]
    date_time = container[2].split(".")[0]

def get_log():
    logs = open(log_file_name, 'r')
    global date_time
    sql_queries = ["insert into cpu_log values ('" + cloud_code + "','" + instance_type + "','" + date_time + "','","insert into memory_log values ('"+ cloud_code + "','" + instance_type + "','" + date_time + "','","insert into filesystem_log values ('"+ cloud_code + "','" + instance_type + "','" + date_time + "','","insert into disk_log values ('"+ cloud_code + "','" + instance_type + "','" + date_time + "','","insert into network_log values ('"+ cloud_code + "','" + instance_type + "','" + date_time + "','"]
    for line in logs:
        if line.startswith('Start Benchmark'):
            container = line.split('_')
            date_time = container[1]
        elif line.startswith('cpu_benchmark'):
            container = line.split('|')
            sql_queries[0] += container[2][:-1] + "','"
        elif line.startswith('memory_benchmark'):
            container = line.split('|')
            sql_queries[1] += container[2][:-1] + "','"
        elif line.startswith('filesystem_benchmark'):
            container = line.split('|')
            sql_queries[2] += container[2][:-1] + "','"
        elif line.startswith('disk_benchmark'):
            container = line.split('|')
            if container[2].endswith("k"):
                iops = float(container[2][:-1]) * 1000
            else:
                iops = float(container[2])
            sql_queries[3] += str(iops) + "','" + container[3][:-1] + "','"
        elif line.startswith('network_benchmark'):
            container = line.split('|')
            sql_queries[4] += container[1].replace(" ","")+"','"+container[2].replace(" ","")+"','" + container[3].replace(" ","") + "','" + container[4].replace(" ","")[:-1] + "');"
            sql_query(sql_queries[4])
            sql_queries[4] = "insert into network_log values ('"+ cloud_code + "','" + instance_type + "','" + date_time + "','"
    for query in sql_queries:
        if len(query) > 70:
            sql_query(query[:-2] + ");")
def main():
    get_instance_info()
    get_log()

main()
