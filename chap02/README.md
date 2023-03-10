# Chapter 02. Taking an OpenStack test-drive
* To interact with OpenStack, you use DevStack
* DevStack helps you to deploy a single-node OpenStack cloud without knowing a great deal about OpenStack and without the need for a bunch of hardware.

## Important things to remember
> [Security groups](#security-groups), [Key pairs](#key-pairs)

## 2.1. What is DevStack
* DevStack was created to make the job of deploying OpenStack in **test** and **development** environment quicker, easier.
* DevStack is a collection of documented Bash shell scripts that are used to prepare an environment for configure, and deploy OpenStack.
* But DevStack is not used to deploy an OpenStack production environment.

## 2.2. Deploying DevStack
* Reading the book.

## 2.3. Using the OpenStack Dashboard
### 2.3.1. Overview screen
* Reading the book.

### 2.3.2. Access & Security Screen

###### \#Security groups
* Imagine that you have a VM instance that is **network policy inaccessible (PI)**.
* In this context, PI refers to the inability to access an instace over the network based in some access-limiting network policy, such as a global rule that denies all network access by default.
* In OpenStack, **security groups** defines rules (**access lists**) to describe access (both incomming and outgoing) on the network level.
* A security group can be created for an individual instance, or collections of instances can share the same security group.
* DevStack creates a default security group that contains rules that allow all IPv4 and IPv6 traffic in (ingress) and out (egress) of virtual machine.
* In short, security groups are like personal firewalls for specific groups of instances of VMs.

###### \#Key pairs
* OpenStack provide a feature called **Key Pairs**.