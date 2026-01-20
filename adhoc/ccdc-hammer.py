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
    private_data_dir=PRIVATE_DATA_DIR,playbook="block-ip.yaml")
    print("Events:")
    for event in r.events:
        print(event['event'])
    print("Final stats:")
    print(r.stats)

    

def main():
    while True:
        print(MENU)
        userin = input("> ")
        print(userin)
        match userin.strip():
            case "1":
                block_ip()
                continue
            case "5":
                quit()
            case _:
                continue

if __name__ == "__main__":
    main()