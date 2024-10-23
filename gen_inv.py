# Generates /etc/host file and inventory file for ansible

import os
import sys

CREDENTIALS = []
HOSTS = []
OS_GROUPS = {
    'linux': [],
    'windows': []
}

CACHE_FILE = ".inv_cache"

class Credentials:
    def __init__(self, username, password):
        self.username = username
        self.password = password
    
    def get_password(self):
        return self.password
    
    def get_username(self):
        return self.username
    
class Host:
    def __init__(self, hostname, ip, creds, os):
        self.hostname = hostname
        self.ip = ip
        self.creds = creds
        self.os = os

    def get_hostname(self):
        return self.hostname

    def get_ip(self):
        return self.ip

    def get_creds(self):
        return self.creds
    
    def get_os(self):
        return self.os
    
    def add_to_host_file(self):
        with open('/etc/hosts', 'a') as f:
            f.write(self.ip + ' ' + self.hostname + '\n')
        
    def add_to_inventory_file(self):
        with open('inventory.ini', 'a+') as f:
            f.write(f"[{self.hostname}]\n")
            if self.os == 'linux':
                OS_GROUPS['linux'].append(self.hostname)
                f.write(f"{self.hostname} ansible_host={self.ip} ansible_user={self.creds.get_username()} ansible_password={self.creds.get_password()} ansible_become_method=sudo ansible_become_pass={self.creds.get_password()}\n")
            elif self.os == 'windows':
                OS_GROUPS['windows'].append(self.hostname)
                f.write(f"{self.hostname} ansible_host={self.ip} ansible_user={self.creds.get_username()} ansible_password={self.creds.get_password()} ansible_connection=psrp ansible_winrm_server_cert_validation=ignore ansible_port=5985\n")

def create_credentials():
    username = input('Enter username: ')
    password = input('Enter password: ')
    creds = Credentials(username, password)
    CREDENTIALS.append(creds)
    return creds

def create_host():
    hostname = input('Enter hostname: ').lower()
    ip = input('Enter IP: ')
    print('Select credentials')
    for i,creds in enumerate(CREDENTIALS):
        print(f"{i+1}. {creds.get_username()}")
    choice = int(input('Enter choice: '))
    creds = CREDENTIALS[choice-1]
    os = input('Enter os group (windows or linux): ')
    host = Host(hostname, ip, creds, os)
    HOSTS.append(host)
    return host

def write_to_cache(obj):
    if isinstance(obj, Credentials):
        with open(CACHE_FILE, 'a') as f:
            f.write(f"creds {obj.get_username()} {obj.get_password()}\n")
    elif isinstance(obj, Host):
        with open(CACHE_FILE, 'a') as f:
            f.write(f"host {obj.get_hostname()} {obj.get_ip()} {obj.get_creds().get_username()} {obj.get_os()}\n")

def read_from_cache():
    with open(CACHE_FILE, 'r') as f:
        for line in f:
            line = line.strip().split(' ')
            if line[0] == 'creds':
                creds = Credentials(line[1], line[2])
                CREDENTIALS.append(creds)
            elif line[0] == 'host':
                creds = None
                for cred in CREDENTIALS:
                    if cred.get_username() == line[3]:
                        creds = cred
                host = Host(line[1], line[2], creds, line[4])
                HOSTS.append(host)

def main():
    if os.path.exists(CACHE_FILE):
        if input('Do you want to use cache? (y/n): ').lower() == 'y':
            read_from_cache()
    else:
        open(CACHE_FILE, 'w').close()
    while True:
        os.system('clear')
        print('1. Create credentials')
        print('2. Create host')
        print('3. List hosts and credentials')
        try:
            choice = int(input('Enter choice: '))
        except:
            choice = None
        if choice == 1:
            try:
                write_to_cache(create_credentials())
            except:
                print('Error creating credentials')
        elif choice == 2:
            try:
                write_to_cache(create_host())
            except:
                print('Error creating host')
        elif choice == 3:
            try:
                print('Credentials:')
                for cred in CREDENTIALS:
                    print(f"\tUsername: {cred.get_username()}")
                    print(f"\tPassword: {cred.get_password()}")
                    print()
                print('Hosts:')
                for host in HOSTS:
                    print(f"Hostname: {host.get_hostname()}")
                    print(f"IP: {host.get_ip()}")
                    print(f"Username: {host.get_creds().get_username()}")
                    print(f"Password: {host.get_creds().get_password()}")
                    print(f"OS: {host.get_os()}")
                    print()
                input()
            except:
                print('Error listing hosts and credentials')
        else:
            break
    try:
        for host in HOSTS:
            host.add_to_host_file()
            host.add_to_inventory_file()
    except:
        print('Error writing to files')

    try:
        with open('inventory.ini', 'a') as f:
            f.write(f"[linux]\n")
            for host in OS_GROUPS['linux']:
                f.write(f"{host}\n")
            f.write(f"[windows]\n")
            for host in OS_GROUPS['windows']:
                f.write(f"{host}\n")
    except:
        print('Error writing to inventory file')

    print("Remember to set [logging] group in inventory file.")

if __name__ == '__main__':
    if os.geteuid() != 0:
        print('This script must be run as root')
        sys.exit()
    main()