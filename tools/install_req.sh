# install requirements to run ansible

# install required packages
sudo apt-get update
sudo apt-get install -y python3-pip libffi-dev libssl-dev git sshpass 

# install required python modules
pip3 install pywinrm pypsrp ansible passlib

echo "export PATH=$HOME/.local/bin:\$PATH" >> ~/.bashrc

# make directories
mkdir -p /opt/audit
mkdir -p /opt/inventory

sudo chmod -R 777 /opt

# make ssh key
ssh-keygen -t ed25519 -C "ansible@rit-ccdc" -f /opt/inventory/id_ed25519 -N ""
cp /opt/inventory/id_ed25519 $HOME/.ssh/id_ed25519
