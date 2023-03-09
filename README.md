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