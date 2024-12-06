# install requirements to run ansible

# ensure root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

# install required packages
apt-get update
apt-get install -y python3-pip libffi-dev libssl-dev git sshpass 

# install required python modules
pip3 install pywinrm pypsrp ansible

echo "export PATH=$HOME/.local/bin:\$PATH" >> ~/.bashrc

# make directories
mkdir -p /opt/audit
mkdir -p /opt/inventory

# make ssh key
ssh-keygen -t ed25519 -C "ansible@rit-ccdc" -f /opt/inventory/id_ed25519 -N ""
cp /opt/inventory/id_ed25519 $HOME/.ssh/id_ed25519
