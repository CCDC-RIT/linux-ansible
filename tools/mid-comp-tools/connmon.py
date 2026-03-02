#!/usr/bin/python3

import psutil
import socket
import os,sys

#COLOR CODE CONTANTS
RED = "\033[91m"
RESET = "\033[0m"

def check_root():
    if os.geteuid() != 0:
        print("Error: This script requires root privileges.")
        print("Please run with 'sudo'.")
        sys.exit(1)  

def get_listening():
    conns = psutil.net_connections(kind='inet')
    print(f"{RED}Listening Ports{RESET}")
    print("Proto\tLocal Address\t\t  Port\t   Status    PID\tProcess Name\t     Process Owner")
    for conn in conns:
        if conn.status == psutil.CONN_LISTEN:
            proto = "TCP" if conn.type == socket.SOCK_STREAM else "UDP" if conn.type == socket.SOCK_DGRAM else "UNKNOWN"
            local_ip = conn.laddr.ip if conn.laddr else "*"
            local_port = conn.laddr.port if conn.laddr else "*"
            process = psutil.Process(conn.pid)
            process_name = process.name()
            process_owner = process.username()
            print(f"{proto:<8}{local_ip:<26}{local_port:<8} {conn.status:<10}{conn.pid:<10} {process_name:<20} {process_owner}")

def get_established():
    conns = psutil.net_connections(kind='inet')
    print(f"\n\n{RED}Established Connections{RESET}")
    print("Proto\tLocal Address\t\t Local Port\tRemote Address\tRemote Port\t Status        PID\t Process Name\t     Process Owner")
    for conn in conns:
        if conn.status == psutil.CONN_ESTABLISHED:
            proto = "TCP" if conn.type == socket.SOCK_STREAM else "UDP" if conn.type == socket.SOCK_DGRAM else "UNKNOWN"
            local_ip = conn.laddr.ip if conn.laddr else "*"
            local_port = conn.laddr.port if conn.laddr else "*"
            remote_ip = conn.raddr.ip if conn.raddr else "*"
            remote_port = conn.raddr.port if conn.raddr else "*"
            process = psutil.Process(conn.pid)
            process_name = process.name()
            process_owner = process.username()
            print(f"{proto:<8}{local_ip:<25}{local_port:<15}{remote_ip:<16}{remote_port:<17}{conn.status:<14}{conn.pid:<10}{process_name:<20}{process_owner}")
            
    

def main():
    check_root()
    get_listening()
    get_established()
    

if __name__ == '__main__':
    main()