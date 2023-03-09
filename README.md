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

* When installing Ubuntu Server, just following the default installation.

* Following this guideline to install DevStack:
  * [https://docs.openstack.org/devstack/latest/](https://docs.openstack.org/devstack/latest/)
  * Note: in the `local.conf` file, you need to change/add the `HOST_IP` to the IP address of the VM.