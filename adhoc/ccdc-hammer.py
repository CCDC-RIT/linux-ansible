#!/usr/bin/python3

import ansible_runner
import os

"""
THE CCDC HAMMER
Python wrapper for adhoc playbooks
"""

MENU = "1. Block IP\n2. Quarantine File\n3. Stop + Disable Service\n4. Change Password\n5. Exit"
PRIVATE_DATA_DIR = '/tmp/ansible-data'

def block_ip():
    ip = input("IP Address To Block: ").strip()
    r = ansible_runner.run(
    private_data_dir=PRIVATE_DATA_DIR,playbook=f"{os.getcwd()}/block-ip.yml",inventory=f"{os.getcwd()}/inventory.ini",extravars={'ip':ip})
    print("Final stats:")
    print(r.stats,end="\n\n")

def quarantine():
    filepath = input("Filepath to quarantine: ").strip()
    r = ansible_runner.run(
    private_data_dir=PRIVATE_DATA_DIR,playbook=f"{os.getcwd()}/quarantine.yml",inventory=f"{os.getcwd()}/inventory.ini",extravars={'filepath':filepath})
    print("Final stats:")
    print(r.stats,end="\n\n")

def killsvc():
    servicename = input("Name of service to stop + disable: ").strip()
    r = ansible_runner.run(private_data_dir=PRIVATE_DATA_DIR,playbook=f"{os.getcwd()}/kill-service.yml",inventory=f"{os.getcwd()}/inventory.ini",extravars={'servicename':servicename})
    print("Final stats:")
    print(r.stats,end="\n\n")

def password_change():
    username = input("Username to reset password for: ").strip()
    newpass = input("New Password: ").strip()
    r = ansible_runner.run(private_data_dir=PRIVATE_DATA_DIR,playbook=f"{os.getcwd()}/password-change.yml",inventory=f"{os.getcwd()}/inventory.ini",extravars={'username':username,'new_pass':newpass})
    print("Final stats:")
    print(r.stats,end="\n\n")

def main():
    print(r"""
 _____ _   _ _____    ____ ____ ____   ____   _   _    _    __  __ __  __ _____ ____  
|_   _| | | | ____|  / ___/ ___|  _ \ / ___| | | | |  / \  |  \/  |  \/  | ____|  _ \ 
  | | | |_| |  _|   | |  | |   | | | | |     | |_| | / _ \ | |\/| | |\/| |  _| | |_) |
  | | |  _  | |___  | |__| |___| |_| | |___  |  _  |/ ___ \| |  | | |  | | |___|  _ < 
  |_| |_| |_|_____|  \____\____|____/ \____| |_| |_/_/   \_\_|  |_|_|  |_|_____|_| \_\
                                                                                        
""")
    print(r"""

                                        _____________
                                       |#############|
                                       |#############|
                                    ___|#############|___
  _________________________________|###################|
 |###############################################|#####|
 |###############################################|#####|
 |###############################################|#####|
 |_______________________________________________|#####|
                                       |#############|
                                       |#############|
                                       |_____________|

""")
    os.makedirs(PRIVATE_DATA_DIR, exist_ok=True)
    while True:
        print(MENU)
        userin = input("> ")
        print(userin)
        match userin.strip():
            case "1":
                block_ip()
                continue
            case "2":
                quarantine()
                continue
            case "3":
                killsvc()
                continue
            case "4":
                password_change()
                continue
            case "5":
                quit()
            case _:
                continue

if __name__ == "__main__":
    main()