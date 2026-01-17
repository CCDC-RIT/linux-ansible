#!/usr/bin/python3

import psutil
import argparse
import socket
import os,sys



def arg_setup():
    msg = "Command line tool for querying information about processes"
    parser = argparse.ArgumentParser(description = msg)
    parser.add_argument("-v", "--verbose", help="increase output verbosity", action="store_true")
    parser.add_argument('id', help="pid of process to look up", type=int) #required argument
    return parser.parse_args()

def check_root():
    if os.geteuid() != 0:
        print("Error: This script requires root privileges.")
        print("Please run with 'sudo'.")
        sys.exit(1)  

def get_process_info(pid):
    process = psutil.Process(pid)
    cmdline = process.cmdline()
    cmdline_str = ""
    for arg in cmdline:
        cmdline_str += arg + " "
    print(f"Process ID: {pid}")
    print(f"Process Name: {process.name()}")
    print(f"Process User: {process.username()}")
    print(f"Process Path: {process.exe()}")
    print(f"Process Command: {cmdline_str}")
    print(f"Process Status: {process.status()}")
    print(f"Process Parent ID: {process.ppid()}")
    try:
        print(f"Process Parent Name: {psutil.Process(process.ppid()).name()}")
    except psutil.NoSuchProcess:
        pass


def verbose(pid):
    files = psutil.Process(pid).open_files()
    try:
        conns = psutil.Process(pid).net_connections()
    except:
        conns = psutil.Process(pid).connections()
    print(f"Process Open Files: ", end="")
    for file in files:
        print(file.path, end=", ")
    print(f"\nProcess Connections:")
    for conn in conns:
        conn_type = "TCP" if conn.type == socket.SOCK_STREAM else "UDP" if conn.type == socket.SOCK_DGRAM else "UNKNOWN"
        print(f"\tConnection Type: {conn_type}")
        print(f"\tLocal Address: {conn.laddr[0]}:{conn.laddr[1]}")
        try:
            print(f"\tRemote Address: {conn.raddr[0]}:{conn.raddr[1]}")
        except IndexError:
            pass
        print(f"\tStatus: {conn.status}")


def main():
    check_root()
    args = arg_setup()
    get_process_info(args.id)
    if args.verbose:
        verbose(args.id)


if __name__ == '__main__':
    main()