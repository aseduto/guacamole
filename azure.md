# Create an azure VM as a Guacamole jump station

Following are the steps to create a vm to use as jump station using azure [az command line](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest).

Use your bash shell. You can change the variable to better reflect your environment.

If you do not have an ssh key generate it with:

```ssh-keygen -f ~/.ssh/guacamole -t dsa```

```bash

GROUP="aseduto"
VM="guacamole"
VNET="${GROUP}vnet"
STORAGE="${GROUP}disks"
SUBNET="${VNET}subnet0"

az group create --name ${GROUP}  --location westeurope
az storage account create --name ${STORAGE} --resource-group ${GROUP}
az network vnet create -g ${GROUP} -n ${VNET} --address-prefix 10.0.0.0/16 --subnet-name ${SUBNET} --subnet-prefix 10.0.0.0/24

az network public-ip create --resource-group ${GROUP} --name "ipssh${VM}"
az network public-ip create --resource-group ${GROUP} --name "iphttp${VM}"

az network nic create --resource-group ${GROUP} --name "nic${VM}" --vnet-name ${VNET} --subnet ${SUBNET}
az network nic ip-config create --name "ipconfig${VM}" --resource-group ${GROUP}  --nic-name "nic${VM}" --vnet-name ${VNET} --subnet ${SUBNET}

az network lb create --resource-group ${GROUP} --name "lb${VM}" --backend-pool-name "pool${VM}" --public-ip-address "iphttp${VM}"
az network lb frontend-ip create --resource-group ${GROUP} --name "ipssh${VM}" --lb-name "lb${VM}" --public-ip-address "ipssh${VM}"

az network nic ip-config address-pool add --resource-group ${GROUP} --lb-name "lb${VM}" --nic-name "nic${VM}" --address-pool "pool${VM}" --ip-config-name "ipconfig${VM}" 
 
az network lb rule create --resource-group ${GROUP} --lb-name "lb${VM}" \
	--frontend-ip-name "ipssh${VM}" \
    --name "lbssh${VM}rule" \
    --protocol tcp \
    --frontend-port 22 \
    --backend-port 22 
	

az network lb rule create --resource-group ${GROUP} --lb-name "lb${VM}" \
    --frontend-ip-name "iphttp${VM}" \
    --name "lbhttps${VM}rule" \
    --protocol tcp \
    --frontend-port 443 \
    --backend-port 443 	

az vm create --name ${VM} --resource-group ${GROUP} --image Debian --ssh-key-value @.ssh/guacamole.pub --admin-username guacamole \
--use-unmanaged-disk --storage-account ${STORAGE} --public-ip-address "" --nics "nic${VM}" --size Standard_B1LS

```

Once your machine is ready you can install docker with [ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#installing-the-control-machine):

```bash

ansible-galaxy install nickjj.docker
ansible-galaxy install geerlingguy.ansible

cat << EOF > site.yml
---

# site.yml



- name: Example
  hosts: "all"
  become: true
  vars:
    docker__state: "latest"
  roles:
    - role: "nickjj.docker"
    tags: ["docker"]
    - role: geerlingguy.ansible
                                
EOF

ansible-playbook setup.yaml -i ,<your machine ip> --key-file=./.ssh/guacamole


```