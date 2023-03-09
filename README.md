* There are two ways to run DevStack in development/testing environment:
  * Using `multipass`.
  * Using VirtualBox.

# 1. Using `multipass` to run DevStack
## 1.1. Pre-requisites
* Turn-off firewall on your host machine.
* Install `multipass` on your host machine.

## 1.2. Installation
* Create instance using `multipass`:
  ```bash
  multipass launch -n openstack -c 6 -m 8G -vvv minikube
  ```
* Interact with the instance:
  ```bash
  multipass shell openstack
  ```
* Following this guideline to install DevStack using `multipass`:
  * [https://docs.openstack.org/devstack/latest/](https://docs.openstack.org/devstack/latest/)

# 2. Using VirtualBox to run DevStack
* Install VirtualBox on your host machine, downloading `*.deb` file from this link and then installing:
  * [https://www.virtualbox.org/wiki/Linux_Downloads](https://www.virtualbox.org/wiki/Linux_Downloads)

* Download the Ubuntu Server ISO image from this link:
  * [https://ubuntu.com/download/server](https://ubuntu.com/download/server)

* Using VirtualBox to create an VM with 4 cores, 6 GB RAM, 50GB diskspace and using bridge network using the network interface of the host machine (use the `ifconfig` and `ping` command to test).
  ![](./img/01.png)

* When installing Ubuntu Server, just following the default installation.

* Following this guideline to install DevStack:
  * [https://docs.openstack.org/devstack/latest/](https://docs.openstack.org/devstack/latest/)
  * Note: in the `local.conf` file, you need to change/add the `HOST_IP` to the IP address of the VM.
    ![](./img/02.png)

# 3. Troubleshooting
* If there is any issue with the installation, you can use the following command to clean up the installation:
  ```bash
  # workdir: devstack
  ./unstack.sh
  ./clean.sh # (optional, god will pray for you)
  ```

* And then you can re-run the installation again.
  ```bash
  # workdir: devstack
  ./stack.sh
  ```

# 4. Interact with OpenStackCLI
* To interact with OpenStack CLI, you need the config file called `admin-openrc`.
* This is the content of this file:
  ```bash
  export OS_PROJECT_DOMAIN_NAME=default
  export OS_USER_DOMAIN_NAME=default
  export OS_PROJECT_NAME=admin
  export OS_USERNAME=admin
  export OS_PASSWORD=secret
  export OS_AUTH_URL=http://192.168.239.196/identity
  export OS_IDENTITY_API_VERSION=3
  export OS_IMAGE_API_VERSION=2
  ```
* With the `OS_AUTH_URL` is the IP address of the VM followed by `/identity`.
* To set up all this environment variables, you can run the following command:
  ```bash
  source admin-openrc
  ```

# 5. Uninstall DevStack
* To uninstall DevStack, you can run the following command:
  ```bash
  # workdir: devstack
  ./unstack.sh
  ./clean.sh
  sudo rm -rf /opt/stack
  ```