# install requirements to run ansible

# install required packages
sudo apt-get update
sudo apt-get install -y python3-pip libffi-dev libssl-dev git sshpass 

# install required python modules
pip3 install pywinrm pypsrp ansible passlib

echo "export PATH=$HOME/.local/bin:\$PATH" >> ~/.bashrc

# make directories
sudo chmod -R 777 /opt

mkdir -p /opt/audit
mkdir -p /opt/inventory

# make ssh key
ssh-keygen -t ed25519 -C "ansible@rit-ccdc" -f /opt/id_ed25519 -N ""
cp /opt/id_ed25519 $HOME/.ssh/id_ed25519
cp /opt/id_ed25519.pub $HOME/.ssh/id_ed25519.pub

echo 'Ensure that you source ~/.bashrc! Or just run this: export PATH=$HOME/.local/bin:\$PATH'

# Install required ansible collections
ansible-galaxy collection install kubernetes.core
