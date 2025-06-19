# install requirements to run ansible

# install required packages
sudo apt-get update
sudo apt-get install -y python3-pip libffi-dev libssl-dev git sshpass 

# install required python modules
pip3 install pywinrm pypsrp ansible passlib

# Install Ansible-cmdb for inventory
pip install ansible-cmdb

echo "export PATH=$HOME/.local/bin:\$PATH" >> ~/.bashrc

# make directories
sudo chmod -R 777 /opt

mkdir -p /opt/audit
mkdir -p /opt/inventory

# make ssh key
ssh-keygen -t ed25519 -C "ansible@rit-ccdc" -f /opt/inventory -N ""
cp /opt/inventory $HOME/.ssh/inventory
cp /opt/inventory.pub $HOME/.ssh/inventory.pub

# Install required ansible collections
ansible-galaxy collection install kubernetes.core

echo 'Ensure that you source ~/.bashrc! Or just run this: export PATH=$HOME/.local/bin:\$PATH'