###### [_↩ Back to `main` branch_](https://github.com/cuongpiger/openstack)

<hr>

###### References
- [https://docs.infomaniak.cloud/documentation/06.high-availability/010.load-balancers](https://docs.infomaniak.cloud/documentation/06.high-availability/010.load-balancers/)

<hr>

# Load Balancers (Octavia)
- Load Balancing as a Service (LBaaS) offers load balancing relying on virtual IPs. For the OpenStack platform, LB (load balancing) is provided to users as a service that provides users with on-demand, ready access to configurable business load balancing scenarios, known as Load Balancing as a service.

- This section present a full use case, other examples are available on the [official documentation](https://docs.openstack.org/octavia/latest/user/guides/basic-cookbook.html).

- **Basic object concepts**:
  |#|Object|Description|
  |-|-|-|
  |1|**loadbalancer**|The root object of the load balancing service, on which the user defines, configures, and operates load balancing. _(Technically, loadbalancers are based on haproxy + VRRP)_.|
  |2|**VIP**|The IP address associated with loadbalancer.| 
  |3|**Listener**|Listener belongs to a loadbalancer, the user can configure the type of external access to the VIP (e.g. protocols, ports). _(Technically, it corresponds to the haproxy listen section)_.|
  |4|**Pool**|Pool belongs to a listener and correponds to the configuration of the backend. _(Technically, this is the bakend section of haproxy)_.|
  |5|**Member**|Members belong to a pool and are real virtual machine IPs. _(Technically, corresponds to the lines starting with `server` of the backend section in `haproxy`)_.|
  |6|**Health Monitor**|Belong to a Pool and periodically perform health checks on Member(s) of the Pool. _(Technically, corresponds to check parameters of the backend section in haproxy)_.|
  |7|**L7 Policy**|A seven-tier forwarding policy that describes the action of packet forwarding (e.g. Forward to Pool, forward to URL, refuse to forward).|
  |8|**L7 Rule**|A seven-tier forwarding rule, under which L7 Policy describes the matching domain for packet forwarding (e.g. Forward to all Members in Pool that have started with webserver).|

# Basic example : 2 virtual machines on a private network + 1 loadbalancer with a public IP

![](./img/01.png)

- The load balancer will also be used to access the 2 backend virtual machines via SSH
- Steps:
    - **Step 1**: create 1 private network + 1 private subnet
    - **Step 2**: create 2 virtual machines on a private network which will be our HTTP backend
    - **Step 3**: create 1 loadbalancer with a public IP in front of the 2 virtual machines
    - **Step 4**: Configure the loadbalancer
    - **Step 5**: configure a basic HTTP server
    - **Step 6**: Health monitor
    - **Step 7**: Add TLS termination

## Step 1: create 1 private network + 1 private subnet
```bash=
openstack network create mynetwork
```
  > ```bash=
  > root@ENG-DEV-OPS-01:/home/cuongdm3# openstack network create mynetwork
  > +---------------------------+--------------------------------------+
  > | Field                     | Value                                |
  > +---------------------------+--------------------------------------+
  > | admin_state_up            | UP                                   |
  > | availability_zone_hints   |                                      |
  > | availability_zones        |                                      |
  > | created_at                | 2023-12-25T05:42:15Z                 |
  > | description               |                                      |
  > | dns_domain                | None                                 |
  > | id                        | f5bf1a47-9267-4db0-8b58-49afd846fae8 |
  > | ipv4_address_scope        | None                                 |
  > | ipv6_address_scope        | None                                 |
  > | is_default                | False                                |
  > | is_vlan_transparent       | None                                 |
  > | mtu                       | 1450                                 |
  > | name                      | mynetwork                            |
  > | port_security_enabled     | True                                 |
  > | project_id                | c430b410b86f412194999216f04ec39a     |
  > | provider:network_type     | vxlan                                |
  > | provider:physical_network | None                                 |
  > | provider:segmentation_id  | 4                                    |
  > | qos_policy_id             | None                                 |
  > | revision_number           | 1                                    |
  > | router:external           | Internal                             |
  > | segments                  | None                                 |
  > | shared                    | False                                |
  > | status                    | ACTIVE                               |
  > | subnets                   |                                      |
  > | tags                      |                                      |
  > | tenant_id                 | c430b410b86f412194999216f04ec39a     |
  > | updated_at                | 2023-12-25T05:42:15Z                 |
  > +---------------------------+--------------------------------------+
  > ```

```bash=
openstack subnet create mysubnet --network mynetwork --dhcp --subnet-range 10.10.10.0/24 \
  --dns-nameserver 8.8.8.8 --dns-nameserver 8.8.4.4 \
  --allocation-pool start=10.10.10.100,end=10.10.10.200
```
  > ```bash=
  > root@ENG-DEV-OPS-01:/home/cuongdm3# openstack subnet create mysubnet --network mynetwork --dhcp --subnet-range 10.10.10.0/24 --dns-nameserver 8.8.8.8 --dns-nameserver 8.8.4.4 --allocation-pool start=10.10.10.100,end=10.10.10.200
  > +----------------------+--------------------------------------+
  > | Field                | Value                                |
  > +----------------------+--------------------------------------+
  > | allocation_pools     | 10.10.10.100-10.10.10.200            |
  > | cidr                 | 10.10.10.0/24                        |
  > | created_at           | 2023-12-25T05:43:56Z                 |
  > | description          |                                      |
  > | dns_nameservers      | 8.8.4.4, 8.8.8.8                     |
  > | dns_publish_fixed_ip | None                                 |
  > | enable_dhcp          | True                                 |
  > | gateway_ip           | 10.10.10.1                           |
  > | host_routes          |                                      |
  > | id                   | cdae1465-0666-42f3-b060-9fbaa02d38a3 |
  > | ip_version           | 4                                    |
  > | ipv6_address_mode    | None                                 |
  > | ipv6_ra_mode         | None                                 |
  > | name                 | mysubnet                             |
  > | network_id           | f5bf1a47-9267-4db0-8b58-49afd846fae8 |
  > | project_id           | c430b410b86f412194999216f04ec39a     |
  > | revision_number      | 0                                    |
  > | segment_id           | None                                 |
  > | service_types        |                                      |
  > | subnetpool_id        | None                                 |
  > | tags                 |                                      |
  > | updated_at           | 2023-12-25T05:43:56Z                 |
  > +----------------------+--------------------------------------+
  > ```

## Step 2: create 2 virtual machines on a private network
```bash=
openstack server create --key-name cuongdm3-keypair --flavor ds4G --image 6d4c5062-bf64-4881-99a2-207573893faf --network mynetwork myloadbalancer-backend-1
```
  > ```bash=
  > root@ENG-DEV-OPS-01:/home/cuongdm3# openstack server create --key-name cuongdm3-keypair --flavor ds4G --image 6d4c5062-bf64-4881-99a2-207573893faf --network mynetwork myloadbalancer-backend-1
  > +-------------------------------------+-----------------------------------------------------------+
  > | Field                               | Value                                                     |
  > +-------------------------------------+-----------------------------------------------------------+
  > | OS-DCF:diskConfig                   | MANUAL                                                    |
  > | OS-EXT-AZ:availability_zone         |                                                           |
  > | OS-EXT-SRV-ATTR:host                | None                                                      |
  > | OS-EXT-SRV-ATTR:hypervisor_hostname | None                                                      |
  > | OS-EXT-SRV-ATTR:instance_name       |                                                           |
  > | OS-EXT-STS:power_state              | NOSTATE                                                   |
  > | OS-EXT-STS:task_state               | scheduling                                                |
  > | OS-EXT-STS:vm_state                 | building                                                  |
  > | OS-SRV-USG:launched_at              | None                                                      |
  > | OS-SRV-USG:terminated_at            | None                                                      |
  > | accessIPv4                          |                                                           |
  > | accessIPv6                          |                                                           |
  > | addresses                           |                                                           |
  > | adminPass                           | ts4e8crgW47s                                              |
  > | config_drive                        |                                                           |
  > | created                             | 2023-12-25T05:45:52Z                                      |
  > | flavor                              | ds4G (d4)                                                 |
  > | hostId                              |                                                           |
  > | id                                  | b2830eda-a60a-4b4e-9b54-9829956afbe1                      |
  > | image                               | Ubuntu-Jammy_amd64 (6d4c5062-bf64-4881-99a2-207573893faf) |
  > | key_name                            | cuongdm3-keypair                                          |
  > | name                                | myloadbalancer-backend-1                                  |
  > | progress                            | 0                                                         |
  > | project_id                          | c430b410b86f412194999216f04ec39a                          |
  > | properties                          |                                                           |
  > | security_groups                     | name='default'                                            |
  > | status                              | BUILD                                                     |
  > | updated                             | 2023-12-25T05:45:52Z                                      |
  > | user_id                             | f2d17b43055643b285864642b07ae854                          |
  > | volumes_attached                    |                                                           |
  > +-------------------------------------+-----------------------------------------------------------+
  > ```

```bash=
openstack server create --key-name cuongdm3-keypair --flavor ds4G --image 6d4c5062-bf64-4881-99a2-207573893faf --network mynetwork myloadbalancer-backend-2
```
  > ```bash=
  > root@ENG-DEV-OPS-01:/home/cuongdm3# openstack server create --key-name cuongdm3-keypair --flavor ds4G --image 6d4c5062-bf64-4881-99a2-207573893faf --network mynetwork myloadbalancer-backend-2
  > +-------------------------------------+-----------------------------------------------------------+
  > | Field                               | Value                                                     |
  > +-------------------------------------+-----------------------------------------------------------+
  > | OS-DCF:diskConfig                   | MANUAL                                                    |
  > | OS-EXT-AZ:availability_zone         |                                                           |
  > | OS-EXT-SRV-ATTR:host                | None                                                      |
  > | OS-EXT-SRV-ATTR:hypervisor_hostname | None                                                      |
  > | OS-EXT-SRV-ATTR:instance_name       |                                                           |
  > | OS-EXT-STS:power_state              | NOSTATE                                                   |
  > | OS-EXT-STS:task_state               | scheduling                                                |
  > | OS-EXT-STS:vm_state                 | building                                                  |
  > | OS-SRV-USG:launched_at              | None                                                      |
  > | OS-SRV-USG:terminated_at            | None                                                      |
  > | accessIPv4                          |                                                           |
  > | accessIPv6                          |                                                           |
  > | addresses                           |                                                           |
  > | adminPass                           | 94gw7FoLceCu                                              |
  > | config_drive                        |                                                           |
  > | created                             | 2023-12-25T05:46:46Z                                      |
  > | flavor                              | ds4G (d4)                                                 |
  > | hostId                              |                                                           |
  > | id                                  | 9b74d342-47ae-4881-b22c-4a9c30e9b344                      |
  > | image                               | Ubuntu-Jammy_amd64 (6d4c5062-bf64-4881-99a2-207573893faf) |
  > | key_name                            | cuongdm3-keypair                                          |
  > | name                                | myloadbalancer-backend-2                                  |
  > | progress                            | 0                                                         |
  > | project_id                          | c430b410b86f412194999216f04ec39a                          |
  > | properties                          |                                                           |
  > | security_groups                     | name='default'                                            |
  > | status                              | BUILD                                                     |
  > | updated                             | 2023-12-25T05:46:46Z                                      |
  > | user_id                             | f2d17b43055643b285864642b07ae854                          |
  > | volumes_attached                    |                                                           |
  > +-------------------------------------+-----------------------------------------------------------+
  > ```

```bash=
openstack server list
```
  > ```bash=
  > root@ENG-DEV-OPS-01:/home/cuongdm3# openstack server list
  > +--------------------------------------+------------------------------------------------+--------+----------------------------------------------------+--------------------------+--------+
  > | ID                                   | Name                                           | Status | Networks                                           | Image                    | Flavor |
  > +--------------------------------------+------------------------------------------------+--------+----------------------------------------------------+--------------------------+--------+
  > | 9b74d342-47ae-4881-b22c-4a9c30e9b344 | myloadbalancer-backend-2                       | BUILD  |                                                    | Ubuntu-Jammy_amd64       | ds4G   |
  > | b2830eda-a60a-4b4e-9b54-9829956afbe1 | myloadbalancer-backend-1                       | ACTIVE | mynetwork=10.10.10.167                             | Ubuntu-Jammy_amd64       | ds4G   |
  > | 9d3c78a6-c5f3-4a58-9a43-57d8f295a843 | lab-jared-sachez-v1-29-0-vqvdirguinzy-node-0   | ACTIVE | LAB-jared-sachez-v1.29.0=10.0.0.86, 49.213.90.198  | N/A (booted from volume) | ds4G   |
  > | cdcc5084-2e01-4b63-9c85-509c0308e760 | lab-jared-sachez-v1-29-0-vqvdirguinzy-master-0 | ACTIVE | LAB-jared-sachez-v1.29.0=10.0.0.239, 49.213.90.203 | N/A (booted from volume) | ds4G   |
  > +--------------------------------------+------------------------------------------------+--------+----------------------------------------------------+--------------------------+--------+
  > ```

- We create a security group to open the ports SSH and HTTP (22 and 80)
```bash=
openstack security group create myloadbalancer-backend-securitygroup
```
  > ```bash=
  > root@ENG-DEV-OPS-01:/home/cuongdm3# openstack security group create myloadbalancer-backend-securitygroup
  > +-----------------+-------------------------------------------------------------------------------------------------------------------------------------------------------+
  > | Field           | Value                                                                                                                                                 |
  > +-----------------+-------------------------------------------------------------------------------------------------------------------------------------------------------+
  > | created_at      | 2023-12-25T05:47:26Z                                                                                                                                  |
  > | description     | myloadbalancer-backend-securitygroup                                                                                                                  |
  > | id              | be869071-ebf6-45ff-aa2f-984610383d69                                                                                                                  |
  > | name            | myloadbalancer-backend-securitygroup                                                                                                                  |
  > | project_id      | c430b410b86f412194999216f04ec39a                                                                                                                      |
  > | revision_number | 1                                                                                                                                                     |
  > | rules           | created_at='2023-12-25T05:47:26Z', direction='egress', ethertype='IPv6', id='0b239f23-2077-41f3-805c-78f91733b2c4', updated_at='2023-12-25T05:47:26Z' |
  > |                 | created_at='2023-12-25T05:47:26Z', direction='egress', ethertype='IPv4', id='88a28e75-bd0a-42ba-9187-cfcdad4a151d', updated_at='2023-12-25T05:47:26Z' |
  > | stateful        | None                                                                                                                                                  |
  > | tags            | []                                                                                                                                                    |
  > | updated_at      | 2023-12-25T05:47:26Z                                                                                                                                  |
  > +-----------------+-------------------------------------------------------------------------------------------------------------------------------------------------------+
  > ```

```bash=
openstack security group rule create --ingress --protocol tcp --dst-port 22 --ethertype IPv4 myloadbalancer-backend-securitygroup
```
  > ```bash=
  > root@ENG-DEV-OPS-01:/home/cuongdm3# openstack security group rule create --ingress --protocol tcp --dst-port 22 --ethertype IPv4 myloadbalancer-backend-securitygroup
  > +-------------------------+--------------------------------------+
  > | Field                   | Value                                |
  > +-------------------------+--------------------------------------+
  > | created_at              | 2023-12-25T05:48:15Z                 |
  > | description             |                                      |
  > | direction               | ingress                              |
  > | ether_type              | IPv4                                 |
  > | id                      | f43c1ca2-77a5-4a5c-94fb-1ca651a4d886 |
  > | name                    | None                                 |
  > | port_range_max          | 22                                   |
  > | port_range_min          | 22                                   |
  > | project_id              | c430b410b86f412194999216f04ec39a     |
  > | protocol                | tcp                                  |
  > | remote_address_group_id | None                                 |
  > | remote_group_id         | None                                 |
  > | remote_ip_prefix        | 0.0.0.0/0                            |
  > | revision_number         | 0                                    |
  > | security_group_id       | be869071-ebf6-45ff-aa2f-984610383d69 |
  > | tags                    | []                                   |
  > | updated_at              | 2023-12-25T05:48:15Z                 |
  > +-------------------------+--------------------------------------+
  > ```

```bash=
openstack security group rule create --ingress --protocol tcp --dst-port 80 --ethertype IPv4 myloadbalancer-backend-securitygroup
```
  > ```bash=
  > root@ENG-DEV-OPS-01:/home/cuongdm3# openstack security group rule create --ingress --protocol tcp --dst-port 80 --ethertype IPv4 myloadbalancer-backend-securitygroup
  > +-------------------------+--------------------------------------+
  > | Field                   | Value                                |
  > +-------------------------+--------------------------------------+
  > | created_at              | 2023-12-25T05:48:43Z                 |
  > | description             |                                      |
  > | direction               | ingress                              |
  > | ether_type              | IPv4                                 |
  > | id                      | 6c8ea00c-4aa1-438e-b9cf-b3c125774ca5 |
  > | name                    | None                                 |
  > | port_range_max          | 80                                   |
  > | port_range_min          | 80                                   |
  > | project_id              | c430b410b86f412194999216f04ec39a     |
  > | protocol                | tcp                                  |
  > | remote_address_group_id | None                                 |
  > | remote_group_id         | None                                 |
  > | remote_ip_prefix        | 0.0.0.0/0                            |
  > | revision_number         | 0                                    |
  > | security_group_id       | be869071-ebf6-45ff-aa2f-984610383d69 |
  > | tags                    | []                                   |
  > | updated_at              | 2023-12-25T05:48:43Z                 |
  > +-------------------------+--------------------------------------+
  > ```

- We associate this security group with the 2 servers.
```bash=
openstack server add security group myloadbalancer-backend-1 myloadbalancer-backend-securitygroup
openstack server add security group myloadbalancer-backend-2 myloadbalancer-backend-securitygroup
```
  > ```bash=
  > root@ENG-DEV-OPS-01:/home/cuongdm3# openstack server add security group myloadbalancer-backend-1 myloadbalancer-backend-securitygroup
  > root@ENG-DEV-OPS-01:/home/cuongdm3# openstack server add security group myloadbalancer-backend-2 myloadbalancer-backend-securitygroup
  > ```

- We now have our 2 servers created but they are on a private network therefore we can't access them yet.

## Step 3: create 1 loadbalancer with a public IP in front of the 2 virtual machines
- We Create our loadbalancer using the infomaniak shared public network:
```bash=
openstack loadbalancer create --name myloadbalancer-01 --vip-network-id external
```
  > ```bash=
  > root@ENG-DEV-OPS-01:/home/cuongdm3# openstack loadbalancer create --name myloadbalancer-01 --vip-network-id external
  > +---------------------+--------------------------------------+
  > | Field               | Value                                |
  > +---------------------+--------------------------------------+
  > | admin_state_up      | True                                 |
  > | availability_zone   |                                      |
  > | created_at          | 2023-12-25T05:50:19                  |
  > | description         |                                      |
  > | flavor_id           | None                                 |
  > | id                  | b1ab8cbd-96ce-4a77-8471-f6d9d3ace115 |
  > | listeners           |                                      |
  > | name                | myloadbalancer-01                    |
  > | operating_status    | OFFLINE                              |
  > | pools               |                                      |
  > | project_id          | c430b410b86f412194999216f04ec39a     |
  > | provider            | amphora                              |
  > | provisioning_status | PENDING_CREATE                       |
  > | updated_at          | None                                 |
  > | vip_address         | 49.213.90.199                        |
  > | vip_network_id      | 4688a041-4945-44e8-8d2e-f95de42d50b1 |
  > | vip_port_id         | 3c4d6981-855f-4ce5-a7db-186b22fa22fe |
  > | vip_qos_policy_id   | None                                 |
  > | vip_subnet_id       | 701d61f7-799e-4ee5-8c9a-b6eba6dcd33c |
  > | tags                |                                      |
  > | additional_vips     |                                      |
  > +---------------------+--------------------------------------+
  > ```

- It will take a few minutes to create the loadbalancer, run the following command until `provisioning_status` is `ACTIVE`:
```bash=
openstack loadbalancer list
```
  > ```bash=
  > root@ENG-DEV-OPS-01:/home/cuongdm3# openstack loadbalancer list
  > +--------------------------------------+-------------------+----------------------------------+---------------+---------------------+------------------+----------+
  > | id                                   | name              | project_id                       | vip_address   | provisioning_status | operating_status | provider |
  > +--------------------------------------+-------------------+----------------------------------+---------------+---------------------+------------------+----------+
  > | b1ab8cbd-96ce-4a77-8471-f6d9d3ace115 | myloadbalancer-01 | c430b410b86f412194999216f04ec39a | 49.213.90.199 | ACTIVE              | OFFLINE          | amphora  |
  > +--------------------------------------+-------------------+----------------------------------+---------------+---------------------+------------------+----------+
  > ```

- The loadbalancer Public IP is `49.213.90.199`.
- We have now 2 backend servers and a load balancer. The next step is to link them.

## Step 4 : Configure the loadbalancer
- Our 2 backend servers (VMs) are on a private network. We will define a port redirection on our loadblancer to access one or the other backend servers.
- Will also redirect the port 80 to the 2 VMs in a round robin manner

```bash=
openstack server list
```
  > ```bash=
  > root@ENG-DEV-OPS-01:/home/cuongdm3# openstack server list
  > +--------------------------------------+------------------------------------------------+--------+--------------------------------------------------------------------------+------------------------------------+---------+
  > | ID                                   | Name                                           | Status | Networks                                                                 | Image                              | Flavor  |
  > +--------------------------------------+------------------------------------------------+--------+--------------------------------------------------------------------------+------------------------------------+---------+
  > | 3026d032-127f-4ad5-ac0a-cff87c91356a | amphora-7079d357-8cac-45e6-b7d5-c795b018f5a7   | ACTIVE | external=49.213.90.201; lb-mgmt-net=172.16.5.238; mynetwork=10.10.10.115 | amphora-x64-haproxy_password.qcow2 | amphora |
  > | 9b74d342-47ae-4881-b22c-4a9c30e9b344 | myloadbalancer-backend-2                       | ACTIVE | mynetwork=10.10.10.187                                                   | Ubuntu-Jammy_amd64                 | ds4G    |
  > | b2830eda-a60a-4b4e-9b54-9829956afbe1 | myloadbalancer-backend-1                       | ACTIVE | mynetwork=10.10.10.167                                                   | Ubuntu-Jammy_amd64                 | ds4G    |
  > | 9d3c78a6-c5f3-4a58-9a43-57d8f295a843 | lab-jared-sachez-v1-29-0-vqvdirguinzy-node-0   | ACTIVE | LAB-jared-sachez-v1.29.0=10.0.0.86, 49.213.90.198                        | N/A (booted from volume)           | ds4G    |
  > | cdcc5084-2e01-4b63-9c85-509c0308e760 | lab-jared-sachez-v1-29-0-vqvdirguinzy-master-0 | ACTIVE | LAB-jared-sachez-v1.29.0=10.0.0.239, 49.213.90.203                       | N/A (booted from volume)           | ds4G    |
  > +--------------------------------------+------------------------------------------------+--------+--------------------------------------------------------------------------+------------------------------------+---------+
  > ```

- We create a SSH listeners for each VM + one for the port 80 which will be common to the 2 VMs. Port 2122 will be used to access myloadbalancer-backend-1 port 22 Port 2222 will be used to access myloadbalancer-backend-2 port 22
```bash=
openstack loadbalancer listener create --name my-ssh-listener-1 --protocol TCP --protocol-port 2122 myloadbalancer-01
openstack loadbalancer listener create --name my-ssh-listener-2 --protocol TCP --protocol-port 2222 myloadbalancer-01
openstack loadbalancer listener create --name my-http-listener --protocol HTTP --protocol-port 80 myloadbalancer-01
```
  > ```bash=
  > root@ENG-DEV-OPS-01:/home/cuongdm3# openstack loadbalancer listener create --name my-ssh-listener-1 --protocol TCP --protocol-port 2122 myloadbalancer-01
  > +-----------------------------+--------------------------------------+
  > | Field                       | Value                                |
  > +-----------------------------+--------------------------------------+
  > | admin_state_up              | True                                 |
  > | connection_limit            | -1                                   |
  > | created_at                  | 2023-12-25T05:51:55                  |
  > | default_pool_id             | None                                 |
  > | default_tls_container_ref   | None                                 |
  > | description                 |                                      |
  > | id                          | 0248e8f4-126c-4c36-8a89-0f89c2a96f51 |
  > | insert_headers              | None                                 |
  > | l7policies                  |                                      |
  > | loadbalancers               | b1ab8cbd-96ce-4a77-8471-f6d9d3ace115 |
  > | name                        | my-ssh-listener-1                    |
  > | operating_status            | OFFLINE                              |
  > | project_id                  | c430b410b86f412194999216f04ec39a     |
  > | protocol                    | TCP                                  |
  > | protocol_port               | 2122                                 |
  > | provisioning_status         | PENDING_CREATE                       |
  > | sni_container_refs          | []                                   |
  > | timeout_client_data         | 50000                                |
  > | timeout_member_connect      | 5000                                 |
  > | timeout_member_data         | 50000                                |
  > | timeout_tcp_inspect         | 0                                    |
  > | updated_at                  | None                                 |
  > | client_ca_tls_container_ref | None                                 |
  > | client_authentication       | NONE                                 |
  > | client_crl_container_ref    | None                                 |
  > | allowed_cidrs               | None                                 |
  > | tls_ciphers                 |                                      |
  > | tls_versions                |                                      |
  > | alpn_protocols              |                                      |
  > | tags                        |                                      |
  > +-----------------------------+--------------------------------------+
  > root@ENG-DEV-OPS-01:/home/cuongdm3# openstack loadbalancer listener create --name my-ssh-listener-2 --protocol TCP --protocol-port 2222 myloadbalancer-01
  > +-----------------------------+--------------------------------------+
  > | Field                       | Value                                |
  > +-----------------------------+--------------------------------------+
  > | admin_state_up              | True                                 |
  > | connection_limit            | -1                                   |
  > | created_at                  | 2023-12-25T05:52:42                  |
  > | default_pool_id             | None                                 |
  > | default_tls_container_ref   | None                                 |
  > | description                 |                                      |
  > | id                          | a72c0566-5de8-40d3-a02c-0db19c0c543a |
  > | insert_headers              | None                                 |
  > | l7policies                  |                                      |
  > | loadbalancers               | b1ab8cbd-96ce-4a77-8471-f6d9d3ace115 |
  > | name                        | my-ssh-listener-2                    |
  > | operating_status            | OFFLINE                              |
  > | project_id                  | c430b410b86f412194999216f04ec39a     |
  > | protocol                    | TCP                                  |
  > | protocol_port               | 2222                                 |
  > | provisioning_status         | PENDING_CREATE                       |
  > | sni_container_refs          | []                                   |
  > | timeout_client_data         | 50000                                |
  > | timeout_member_connect      | 5000                                 |
  > | timeout_member_data         | 50000                                |
  > | timeout_tcp_inspect         | 0                                    |
  > | updated_at                  | None                                 |
  > | client_ca_tls_container_ref | None                                 |
  > | client_authentication       | NONE                                 |
  > | client_crl_container_ref    | None                                 |
  > | allowed_cidrs               | None                                 |
  > | tls_ciphers                 |                                      |
  > | tls_versions                |                                      |
  > | alpn_protocols              |                                      |
  > | tags                        |                                      |
  > +-----------------------------+--------------------------------------+
  > root@ENG-DEV-OPS-01:/home/cuongdm3# openstack loadbalancer listener create --name my-http-listener --protocol HTTP --protocol-port 80 myloadbalancer-01
  > +-----------------------------+--------------------------------------+
  > | Field                       | Value                                |
  > +-----------------------------+--------------------------------------+
  > | admin_state_up              | True                                 |
  > | connection_limit            | -1                                   |
  > | created_at                  | 2023-12-25T05:52:50                  |
  > | default_pool_id             | None                                 |
  > | default_tls_container_ref   | None                                 |
  > | description                 |                                      |
  > | id                          | 21f36ab9-af77-4d81-a4b4-1285845e94e8 |
  > | insert_headers              | None                                 |
  > | l7policies                  |                                      |
  > | loadbalancers               | b1ab8cbd-96ce-4a77-8471-f6d9d3ace115 |
  > | name                        | my-http-listener                     |
  > | operating_status            | OFFLINE                              |
  > | project_id                  | c430b410b86f412194999216f04ec39a     |
  > | protocol                    | HTTP                                 |
  > | protocol_port               | 80                                   |
  > | provisioning_status         | PENDING_CREATE                       |
  > | sni_container_refs          | []                                   |
  > | timeout_client_data         | 50000                                |
  > | timeout_member_connect      | 5000                                 |
  > | timeout_member_data         | 50000                                |
  > | timeout_tcp_inspect         | 0                                    |
  > | updated_at                  | None                                 |
  > | client_ca_tls_container_ref | None                                 |
  > | client_authentication       | NONE                                 |
  > | client_crl_container_ref    | None                                 |
  > | allowed_cidrs               | None                                 |
  > | tls_ciphers                 |                                      |
  > | tls_versions                |                                      |
  > | alpn_protocols              |                                      |
  > | tags                        |                                      |
  > +-----------------------------+--------------------------------------+
  > ```


- We create the pools and add the members
```bash=
openstack loadbalancer pool create --name my-ssh-pool-1 --lb-algorithm ROUND_ROBIN --listener my-ssh-listener-1 --protocol TCP --session-persistence type=SOURCE_IP
openstack loadbalancer pool create --name my-ssh-pool-2 --lb-algorithm ROUND_ROBIN --listener my-ssh-listener-2 --protocol TCP --session-persistence type=SOURCE_IP
openstack loadbalancer pool create --name my-http-pool --lb-algorithm ROUND_ROBIN --listener my-http-listener --protocol HTTP
```

  > ```bash=
  > root@ENG-DEV-OPS-01:/home/cuongdm3# openstack loadbalancer pool create --name my-ssh-pool-1 --lb-algorithm ROUND_ROBIN --listener my-ssh-listener-1 --protocol TCP --session-persistence type=SOURCE_IP
  > +----------------------+--------------------------------------+
  > | Field                | Value                                |
  > +----------------------+--------------------------------------+
  > | admin_state_up       | True                                 |
  > | created_at           | 2023-12-25T05:53:33                  |
  > | description          |                                      |
  > | healthmonitor_id     |                                      |
  > | id                   | 67855985-3ea6-4452-81b4-33a8d04f276a |
  > | lb_algorithm         | ROUND_ROBIN                          |
  > | listeners            | 0248e8f4-126c-4c36-8a89-0f89c2a96f51 |
  > | loadbalancers        | b1ab8cbd-96ce-4a77-8471-f6d9d3ace115 |
  > | members              |                                      |
  > | name                 | my-ssh-pool-1                        |
  > | operating_status     | OFFLINE                              |
  > | project_id           | c430b410b86f412194999216f04ec39a     |
  > | protocol             | TCP                                  |
  > | provisioning_status  | PENDING_CREATE                       |
  > | session_persistence  | type=SOURCE_IP                       |
  > |                      | cookie_name=None                     |
  > |                      | persistence_timeout=None             |
  > |                      | persistence_granularity=None         |
  > | updated_at           | None                                 |
  > | tls_container_ref    | None                                 |
  > | ca_tls_container_ref | None                                 |
  > | crl_container_ref    | None                                 |
  > | tls_enabled          | False                                |
  > | tls_ciphers          |                                      |
  > | tls_versions         |                                      |
  > | tags                 |                                      |
  > | alpn_protocols       |                                      |
  > +----------------------+--------------------------------------+
  > root@ENG-DEV-OPS-01:/home/cuongdm3# openstack loadbalancer pool create --name my-ssh-pool-2 --lb-algorithm ROUND_ROBIN --listener my-ssh-listener-2 --protocol TCP --session-persistence type=SOURCE_IP
  > +----------------------+--------------------------------------+
  > | Field                | Value                                |
  > +----------------------+--------------------------------------+
  > | admin_state_up       | True                                 |
  > | created_at           | 2023-12-25T05:53:48                  |
  > | description          |                                      |
  > | healthmonitor_id     |                                      |
  > | id                   | b65b8dea-27df-4937-834e-f3c97bb9d60b |
  > | lb_algorithm         | ROUND_ROBIN                          |
  > | listeners            | a72c0566-5de8-40d3-a02c-0db19c0c543a |
  > | loadbalancers        | b1ab8cbd-96ce-4a77-8471-f6d9d3ace115 |
  > | members              |                                      |
  > | name                 | my-ssh-pool-2                        |
  > | operating_status     | OFFLINE                              |
  > | project_id           | c430b410b86f412194999216f04ec39a     |
  > | protocol             | TCP                                  |
  > | provisioning_status  | PENDING_CREATE                       |
  > | session_persistence  | type=SOURCE_IP                       |
  > |                      | cookie_name=None                     |
  > |                      | persistence_timeout=None             |
  > |                      | persistence_granularity=None         |
  > | updated_at           | None                                 |
  > | tls_container_ref    | None                                 |
  > | ca_tls_container_ref | None                                 |
  > | crl_container_ref    | None                                 |
  > | tls_enabled          | False                                |
  > | tls_ciphers          |                                      |
  > | tls_versions         |                                      |
  > | tags                 |                                      |
  > | alpn_protocols       |                                      |
  > +----------------------+--------------------------------------+
  > root@ENG-DEV-OPS-01:/home/cuongdm3# openstack loadbalancer pool create --name my-http-pool --lb-algorithm ROUND_ROBIN --listener my-http-listener --protocol HTTP
  > +----------------------+--------------------------------------+
  > | Field                | Value                                |
  > +----------------------+--------------------------------------+
  > | admin_state_up       | True                                 |
  > | created_at           | 2023-12-25T05:53:58                  |
  > | description          |                                      |
  > | healthmonitor_id     |                                      |
  > | id                   | 8579b7de-46bb-4218-85f5-3ab3e7bce370 |
  > | lb_algorithm         | ROUND_ROBIN                          |
  > | listeners            | 21f36ab9-af77-4d81-a4b4-1285845e94e8 |
  > | loadbalancers        | b1ab8cbd-96ce-4a77-8471-f6d9d3ace115 |
  > | members              |                                      |
  > | name                 | my-http-pool                         |
  > | operating_status     | OFFLINE                              |
  > | project_id           | c430b410b86f412194999216f04ec39a     |
  > | protocol             | HTTP                                 |
  > | provisioning_status  | PENDING_CREATE                       |
  > | session_persistence  | None                                 |
  > | updated_at           | None                                 |
  > | tls_container_ref    | None                                 |
  > | ca_tls_container_ref | None                                 |
  > | crl_container_ref    | None                                 |
  > | tls_enabled          | False                                |
  > | tls_ciphers          |                                      |
  > | tls_versions         |                                      |
  > | tags                 |                                      |
  > | alpn_protocols       |                                      |
  > +----------------------+--------------------------------------+
  > ```

```bash=
openstack loadbalancer member create --subnet-id mysubnet --address 10.10.10.167 --protocol-port 22 my-ssh-pool-1
openstack loadbalancer member create --subnet-id mysubnet --address 10.10.10.187 --protocol-port 22 my-ssh-pool-2
openstack loadbalancer member create --subnet-id mysubnet --address 10.10.10.167 --protocol-port 80 my-http-pool
openstack loadbalancer member create --subnet-id mysubnet --address 10.10.10.187 --protocol-port 80 my-http-pool
```

  > ```bash=
  > root@ENG-DEV-OPS-01:/home/cuongdm3# openstack loadbalancer member create --subnet-id mysubnet --address 10.10.10.167 --protocol-port 22 my-ssh-pool-1
  > +---------------------+--------------------------------------+
  > | Field               | Value                                |
  > +---------------------+--------------------------------------+
  > | address             | 10.10.10.167                         |
  > | admin_state_up      | True                                 |
  > | created_at          | 2023-12-25T06:48:28                  |
  > | id                  | cfa20beb-c506-4298-a5ae-ce185998ac43 |
  > | name                |                                      |
  > | operating_status    | NO_MONITOR                           |
  > | project_id          | c430b410b86f412194999216f04ec39a     |
  > | protocol_port       | 22                                   |
  > | provisioning_status | PENDING_CREATE                       |
  > | subnet_id           | cdae1465-0666-42f3-b060-9fbaa02d38a3 |
  > | updated_at          | None                                 |
  > | weight              | 1                                    |
  > | monitor_port        | None                                 |
  > | monitor_address     | None                                 |
  > | backup              | False                                |
  > | tags                |                                      |
  > +---------------------+--------------------------------------+
  > root@ENG-DEV-OPS-01:/home/cuongdm3# openstack loadbalancer member create --subnet-id mysubnet --address 10.10.10.187 --protocol-port 22 my-ssh-pool-2
  > +---------------------+--------------------------------------+
  > | Field               | Value                                |
  > +---------------------+--------------------------------------+
  > | address             | 10.10.10.187                         |
  > | admin_state_up      | True                                 |
  > | created_at          | 2023-12-25T06:48:38                  |
  > | id                  | 984b4084-dd4e-4a01-a204-c21042468d10 |
  > | name                |                                      |
  > | operating_status    | NO_MONITOR                           |
  > | project_id          | c430b410b86f412194999216f04ec39a     |
  > | protocol_port       | 22                                   |
  > | provisioning_status | PENDING_CREATE                       |
  > | subnet_id           | cdae1465-0666-42f3-b060-9fbaa02d38a3 |
  > | updated_at          | None                                 |
  > | weight              | 1                                    |
  > | monitor_port        | None                                 |
  > | monitor_address     | None                                 |
  > | backup              | False                                |
  > | tags                |                                      |
  > +---------------------+--------------------------------------+
  > root@ENG-DEV-OPS-01:/home/cuongdm3# openstack loadbalancer member create --subnet-id mysubnet --address 10.10.10.167 --protocol-port 80 my-http-pool
  > +---------------------+--------------------------------------+
  > | Field               | Value                                |
  > +---------------------+--------------------------------------+
  > | address             | 10.10.10.167                         |
  > | admin_state_up      | True                                 |
  > | created_at          | 2023-12-25T06:48:48                  |
  > | id                  | eba49775-bf1a-416f-b6f3-445a7eea9945 |
  > | name                |                                      |
  > | operating_status    | NO_MONITOR                           |
  > | project_id          | c430b410b86f412194999216f04ec39a     |
  > | protocol_port       | 80                                   |
  > | provisioning_status | PENDING_CREATE                       |
  > | subnet_id           | cdae1465-0666-42f3-b060-9fbaa02d38a3 |
  > | updated_at          | None                                 |
  > | weight              | 1                                    |
  > | monitor_port        | None                                 |
  > | monitor_address     | None                                 |
  > | backup              | False                                |
  > | tags                |                                      |
  > +---------------------+--------------------------------------+
  > root@ENG-DEV-OPS-01:/home/cuongdm3# openstack loadbalancer member create --subnet-id mysubnet --address 10.10.10.187 --protocol-port 80 my-http-pool
  > +---------------------+--------------------------------------+
  > | Field               | Value                                |
  > +---------------------+--------------------------------------+
  > | address             | 10.10.10.187                         |
  > | admin_state_up      | True                                 |
  > | created_at          | 2023-12-25T06:48:56                  |
  > | id                  | 8e6414c8-0415-4934-a13a-e079626f2c11 |
  > | name                |                                      |
  > | operating_status    | NO_MONITOR                           |
  > | project_id          | c430b410b86f412194999216f04ec39a     |
  > | protocol_port       | 80                                   |
  > | provisioning_status | PENDING_CREATE                       |
  > | subnet_id           | cdae1465-0666-42f3-b060-9fbaa02d38a3 |
  > | updated_at          | None                                 |
  > | weight              | 1                                    |
  > | monitor_port        | None                                 |
  > | monitor_address     | None                                 |
  > | backup              | False                                |
  > | tags                |                                      |
  > +---------------------+--------------------------------------+
  > ```

- You should now be able to ssh servers `myloadbalancer-backend-1` and `myloadbalancer-backend-2` using the loadbalancer public ip, currently the VM can not access the internet, we will fix this in the next step:
```bash=
ssh ubuntu@49.213.90.199 -p 2122 -i ./keys/cuongdm3-keypair.pem
```

  > ```bash=
  > root@ENG-DEV-OPS-01:/home/cuongdm3# ssh ubuntu@49.213.90.199 -p 2122 -i ./keys/cuongdm3-keypair.pem 
  > Welcome to Ubuntu 22.04.2 LTS (GNU/Linux 5.15.0-76-generic x86_64)
  > 
  >  * Documentation:  https://help.ubuntu.com
  >  * Management:     https://landscape.canonical.com
  >  * Support:        https://ubuntu.com/advantage
  > 
  >   System information as of Mon Dec 25 06:52:09 UTC 2023
  > 
  >   System load:  0.0078125         Processes:             118
  >   Usage of /:   7.5% of 19.20GB   Users logged in:       1
  >   Memory usage: 5%                IPv4 address for ens3: 10.10.10.167
  >   Swap usage:   0%
  > 
  > 
  > Expanded Security Maintenance for Applications is not enabled.
  > 
  > 0 updates can be applied immediately.
  > 
  > Enable ESM Apps to receive additional future security updates.
  > See https://ubuntu.com/esm or run: sudo pro status
  > 
  > 
  > The list of available updates is more than a week old.
  > To check for new updates run: sudo apt update
  > Failed to connect to https://changelogs.ubuntu.com/meta-release-lts. Check your Internet connection or proxy settings
  > 
  > 
  > Last login: Mon Dec 25 06:50:23 2023 from 10.10.10.115
  > To run a command as administrator (user "root"), use "sudo <command>".
  > See "man sudo_root" for details.
  > 
  > ubuntu@myloadbalancer-backend-1:~$
  > ```

```bash=
ssh ubuntu@49.213.90.199 -p 2222 -i ./keys/cuongdm3-keypair.pem 
```

  > ```bash=
  > root@ENG-DEV-OPS-01:/home/cuongdm3# ssh ubuntu@49.213.90.199 -p 2222 -i ./keys/cuongdm3-keypair.pem 
  > The authenticity of host '[49.213.90.199]:2222 ([49.213.90.199]:2222)' can't be established.
  > ECDSA key fingerprint is SHA256:Fo8hiwWrTTibKTiIPvPPXwYdi6y+ApNI/d+Kqno2CI4.
  > Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
  > Warning: Permanently added '[49.213.90.199]:2222' (ECDSA) to the list of known hosts.
  > Welcome to Ubuntu 22.04.2 LTS (GNU/Linux 5.15.0-76-generic x86_64)
  > 
  >  * Documentation:  https://help.ubuntu.com
  >  * Management:     https://landscape.canonical.com
  >  * Support:        https://ubuntu.com/advantage
  > 
  >   System information as of Mon Dec 25 06:53:00 UTC 2023
  > 
  >   System load:  0.0               Processes:             112
  >   Usage of /:   7.5% of 19.20GB   Users logged in:       0
  >   Memory usage: 5%                IPv4 address for ens3: 10.10.10.187
  >   Swap usage:   0%
  > 
  > Expanded Security Maintenance for Applications is not enabled.
  > 
  > 0 updates can be applied immediately.
  > 
  > Enable ESM Apps to receive additional future security updates.
  > See https://ubuntu.com/esm or run: sudo pro status
  > 
  > 
  > The list of available updates is more than a week old.
  > To check for new updates run: sudo apt update
  > 
  > 
  > The programs included with the Ubuntu system are free software;
  > the exact distribution terms for each program are described in the
  > individual files in /usr/share/doc/*/copyright.
  > 
  > Ubuntu comes with ABSOLUTELY NO WARRANTY, to the extent permitted by
  > applicable law.
  > 
  > To run a command as administrator (user "root"), use "sudo <command>".
  > See "man sudo_root" for details.
  > 
  > ubuntu@myloadbalancer-backend-2:~$
  > ```

## Step 5: configure a basic HTTP server
- Internet access is required to install packages Your VMs are on a private network therefore with no internet access. You can provide internet access to your VMs this way:
```bash
openstack router create myrouter-to-access-internet
openstack router set --external-gateway external myrouter-to-access-internet
openstack router add subnet myrouter-to-access-internet mysubnet
```

  > ```bash=
  > root@ENG-DEV-OPS-01:/home/cuongdm3# openstack router create myrouter-to-access-internet
  > +-------------------------+--------------------------------------+
  > | Field                   | Value                                |
  > +-------------------------+--------------------------------------+
  > | admin_state_up          | UP                                   |
  > | availability_zone_hints |                                      |
  > | availability_zones      |                                      |
  > | created_at              | 2023-12-25T06:53:09Z                 |
  > | description             |                                      |
  > | distributed             | False                                |
  > | enable_ndp_proxy        | None                                 |
  > | external_gateway_info   | null                                 |
  > | flavor_id               | None                                 |
  > | ha                      | False                                |
  > | id                      | 075cd484-3cbb-4392-88e4-ae71bb847a41 |
  > | name                    | myrouter-to-access-internet          |
  > | project_id              | c430b410b86f412194999216f04ec39a     |
  > | revision_number         | 1                                    |
  > | routes                  |                                      |
  > | status                  | ACTIVE                               |
  > | tags                    |                                      |
  > | tenant_id               | c430b410b86f412194999216f04ec39a     |
  > | updated_at              | 2023-12-25T06:53:09Z                 |
  > +-------------------------+--------------------------------------+
  > root@ENG-DEV-OPS-01:/home/cuongdm3# openstack router set --external-gateway external myrouter-to-access-internet
  > root@ENG-DEV-OPS-01:/home/cuongdm3# openstack router add subnet myrouter-to-access-internet mysubnet
  > ```

- Install apache2 on both VMs: 
```bash=
ssh ubuntu@49.213.90.199 -p 2122 -i ./keys/cuongdm3-keypair.pem

# inside the VM
apt update && apt install -y apache2
```

```bash=
ssh ubuntu@49.213.90.199 -p 2222 -i ./keys/cuongdm3-keypair.pem

# inside the VM
apt update && apt install -y apache2
```

- You can now open a web browser and execute `curl http://49.213.90.199` you should see the Apache2 welcome page.

- Once you configured your VMs, we advise you to delete the router otherwise you'll be charged for one public IP (the external-gateway IP of myrouter-to-access-internet).
```bash=
openstack router remove subnet myrouter-to-access-internet mysubnet
openstack router delete myrouter-to-access-internet
```


## Step 6: Health monitor
- Health monitor corresponds to amphora VMs (Loadbalancer) checking that your backend VMs respond properly. In case one of your backend HTTP VM is unreachable for some reason, the loadbalancer will stop sending requests to that VM. Without healthmonitor the loadbalancer has no way to know if your backend VMs work as expected.
- In our case we deployed a HTTP service so we'll configure a HTTP health monitor check the url `/`.
```bash=
openstack loadbalancer healthmonitor create --name http-monitor \
                                            --delay 7 \
                                            --timeout 5 \
                                            --max-retries 3 \
                                            --url-path / \
                                            --expected-codes 200,201 \
                                            --type HTTP my-http-pool
```


  > ```bash=
  > root@ENG-DEV-OPS-01:/home/cuongdm3# openstack loadbalancer healthmonitor create --name http-monitor \
  > >                                             --delay 7 \
  > >                                             --timeout 5 \
  > >                                             --max-retries 3 \
  > >                                             --url-path / \
  > >                                             --expected-codes 200,201 \
  > >                                             --type HTTP my-http-pool
  > +---------------------+--------------------------------------+
  > | Field               | Value                                |
  > +---------------------+--------------------------------------+
  > | project_id          | c430b410b86f412194999216f04ec39a     |
  > | name                | http-monitor                         |
  > | admin_state_up      | True                                 |
  > | pools               | 8579b7de-46bb-4218-85f5-3ab3e7bce370 |
  > | created_at          | 2023-12-25T08:20:06                  |
  > | provisioning_status | PENDING_CREATE                       |
  > | updated_at          | None                                 |
  > | delay               | 7                                    |
  > | expected_codes      | 200,201                              |
  > | max_retries         | 3                                    |
  > | http_method         | GET                                  |
  > | timeout             | 5                                    |
  > | max_retries_down    | 3                                    |
  > | url_path            | /                                    |
  > | type                | HTTP                                 |
  > | id                  | f7f1ef33-4b4e-4e99-96cb-e945792c05c0 |
  > | operating_status    | OFFLINE                              |
  > | http_version        | None                                 |
  > | domain_name         | None                                 |
  > | tags                |                                      |
  > +---------------------+--------------------------------------+
  > ```

- Can check the healthmonitor status using the following command:
```bash=
openstack loadbalancer healthmonitor list
```
  > ```bash=
  > root@ENG-DEV-OPS-01:/home/cuongdm3# openstack loadbalancer healthmonitor list                  
  > +--------------------------------------+--------------+----------------------------------+------+----------------+
  > | id                                   | name         | project_id                       | type | admin_state_up |
  > +--------------------------------------+--------------+----------------------------------+------+----------------+
  > | f7f1ef33-4b4e-4e99-96cb-e945792c05c0 | http-monitor | c430b410b86f412194999216f04ec39a | HTTP | True           |
  > +--------------------------------------+--------------+----------------------------------+------+----------------+
  > ```

- We should see GET / requests on our backend VMs from both amphora VMs (loadbalancer)
```bash=
ssh ubuntu@49.213.90.199 -p 2122 -i ./keys/cuongdm3-keypair.pem

# inside the VM
tail -f /var/log/apache2/access.log
```

  > ```bash=
  > root@ENG-DEV-OPS-01:/home/cuongdm3# ssh ubuntu@49.213.90.199 -p 2122 -i ./keys/cuongdm3-keypair.pem
  > Welcome to Ubuntu 22.04.2 LTS (GNU/Linux 5.15.0-76-generic x86_64)
  > 
  >  * Documentation:  https://help.ubuntu.com
  >  * Management:     https://landscape.canonical.com
  >  * Support:        https://ubuntu.com/advantage
  > 
  >   System information as of Mon Dec 25 08:24:13 UTC 2023
  > 
  >   System load:  0.0               Processes:             120
  >   Usage of /:   8.6% of 19.20GB   Users logged in:       1
  >   Memory usage: 6%                IPv4 address for ens3: 10.10.10.167
  >   Swap usage:   0%
  > 
  >  * Strictly confined Kubernetes makes edge and IoT secure. Learn how MicroK8s
  >    just raised the bar for easy, resilient and secure K8s cluster deployment.
  > 
  >    https://ubuntu.com/engage/secure-kubernetes-at-the-edge
  > 
  > Expanded Security Maintenance for Applications is not enabled.
  > 
  > 123 updates can be applied immediately.
  > 71 of these updates are standard security updates.
  > To see these additional updates run: apt list --upgradable
  > 
  > Enable ESM Apps to receive additional future security updates.
  > See https://ubuntu.com/esm or run: sudo pro status
  > 
  > Failed to connect to https://changelogs.ubuntu.com/meta-release-lts. Check your Internet connection or proxy settings
  > 
  > 
  > Last login: Mon Dec 25 06:57:14 2023 from 10.10.10.115
  > 
  > ubuntu@myloadbalancer-backend-1:~$ tail -f /var/log/apache2/access.log
  > 10.10.10.115 - - [25/Dec/2023:08:23:23 +0000] "GET / HTTP/1.0" 200 10945 "-" "-"
  > 10.10.10.115 - - [25/Dec/2023:08:23:30 +0000] "GET / HTTP/1.0" 200 10945 "-" "-"
  > 10.10.10.115 - - [25/Dec/2023:08:23:37 +0000] "GET / HTTP/1.0" 200 10945 "-" "-"
  > 10.10.10.115 - - [25/Dec/2023:08:23:44 +0000] "GET / HTTP/1.0" 200 10945 "-" "-"
  > 10.10.10.115 - - [25/Dec/2023:08:23:51 +0000] "GET / HTTP/1.0" 200 10945 "-" "-"
  > 10.10.10.115 - - [25/Dec/2023:08:23:58 +0000] "GET / HTTP/1.0" 200 10945 "-" "-"
  > 10.10.10.115 - - [25/Dec/2023:08:24:05 +0000] "GET / HTTP/1.0" 200 10945 "-" "-"
  > 10.10.10.115 - - [25/Dec/2023:08:24:12 +0000] "GET / HTTP/1.0" 200 10945 "-" "-"
  > 10.10.10.115 - - [25/Dec/2023:08:24:19 +0000] "GET / HTTP/1.0" 200 10945 "-" "-"
  > 10.10.10.115 - - [25/Dec/2023:08:24:26 +0000] "GET / HTTP/1.0" 200 10945 "-" "-"
  > ```

## Step 7: Add TLS termination
This section describes the steps to create add TLS terminated traffic.
- First of all we have generate a test certificate.
```bash=
openssl req -newkey rsa:2048 -x509 -sha256 -days 365 -nodes \
            -out tls.crt -keyout tls.key \
            -subj "/CN=myloadbalancer-01.mydomain.vngcloud.vn/emailAddress=cuongdm3@vng.com.vn"
```
  > ```bash=
  > root@ENG-DEV-OPS-01:/home/cuongdm3# openssl req -newkey rsa:2048 -x509 -sha256 -days 365 -nodes \
  > >             -out tls.crt -keyout tls.key \
  > >             -subj "/CN=myloadbalancer-01.mydomain.vngcloud.vn/emailAddress=cuongdm3@vng.com.vn"
  > Generating a RSA private key
  > .................+++++
  > ..................................+++++
  > writing new private key to 'tls.key'
  > -----
  > ```

- Combine the individual cert/key to a single PKCS12 file
```bash=
openssl pkcs12 -export -inkey tls.key -in tls.crt -passout pass: -out tls.p12
```

- Check the certificate is valid
```bash=
openssl pkcs12 -in tls.p12 -noout -info
```

  > ```bash=
  > root@ENG-DEV-OPS-01:/home/cuongdm3# openssl pkcs12 -in tls.p12 -noout -info
  > Enter Import Password:  # press enter to leave it empty
  > MAC: sha1, Iteration 2048
  > MAC length: 20, salt length: 8
  > PKCS7 Encrypted data: pbeWithSHA1And40BitRC2-CBC, Iteration 2048
  > Certificate bag
  > PKCS7 Data
  > Shrouded Keybag: pbeWithSHA1And3-KeyTripleDES-CBC, Iteration 2048
  > ```

- Next we have to store the certificate in Barbican (OpenStack's secret store)
```bash=
openstack secret store --name='my_tls_secret' -t 'application/octet-stream' -e 'base64' --payload="$(base64 < tls.p12)"
```

  > ```bash=
  > root@ENG-DEV-OPS-01:/home/cuongdm3# openstack secret store --name='my_tls_secret' -t 'application/octet-stream' -e 'base64' --payload="$(base64 < tls.p12)"
  > +---------------+------------------------------------------------------------------------+
  > | Field         | Value                                                                  |
  > +---------------+------------------------------------------------------------------------+
  > | Secret href   | http://10.76.0.50:9311/v1/secrets/b2768b5e-ae64-4709-801a-680abaaffff0 |
  > | Name          | my_tls_secret                                                          |
  > | Created       | None                                                                   |
  > | Status        | None                                                                   |
  > | Content types | {'default': 'application/octet-stream'}                                |
  > | Algorithm     | aes                                                                    |
  > | Bit length    | 256                                                                    |
  > | Secret type   | opaque                                                                 |
  > | Mode          | cbc                                                                    |
  > | Expiration    | None                                                                   |
  > +---------------+------------------------------------------------------------------------+
  > ```

- We create a new loadbalancer listener port `443`
```bash=
openstack loadbalancer listener create --fit-width --protocol-port 443 \
	--protocol TERMINATED_HTTPS --name my-https-listener \
	--default-tls-container=$(openstack secret list | awk '/ my_tls_secret / {print $2}') myloadbalancer-01
```

  > ```bash=
  > root@ENG-DEV-OPS-01:/home/cuongdm3# openstack loadbalancer listener create --fit-width --protocol-port 443 \
  > > --protocol TERMINATED_HTTPS --name my-https-listener \
  > > --default-tls-container=$(openstack secret list | awk '/ my_tls_secret / {print $2}') myloadbalancer-01
  > +-----------------------------+------------------------------------------------------------------------+
  > | Field                       | Value                                                                  |
  > +-----------------------------+------------------------------------------------------------------------+
  > | admin_state_up              | True                                                                   |
  > | connection_limit            | -1                                                                     |
  > | created_at                  | 2023-12-25T08:35:31                                                    |
  > | default_pool_id             | None                                                                   |
  > | default_tls_container_ref   | http://10.76.0.50:9311/v1/secrets/b2768b5e-ae64-4709-801a-680abaaffff0 |
  > | description                 |                                                                        |
  > | id                          | be04de0f-5db3-47b6-b224-f6ed22034830                                   |
  > | insert_headers              | None                                                                   |
  > | l7policies                  |                                                                        |
  > | loadbalancers               | b1ab8cbd-96ce-4a77-8471-f6d9d3ace115                                   |
  > | name                        | my-https-listener                                                      |
  > | operating_status            | OFFLINE                                                                |
  > | project_id                  | c430b410b86f412194999216f04ec39a                                       |
  > | protocol                    | TERMINATED_HTTPS                                                       |
  > | protocol_port               | 443                                                                    |
  > | provisioning_status         | PENDING_CREATE                                                         |
  > | sni_container_refs          | []                                                                     |
  > | timeout_client_data         | 50000                                                                  |
  > | timeout_member_connect      | 5000                                                                   |
  > | timeout_member_data         | 50000                                                                  |
  > | timeout_tcp_inspect         | 0                                                                      |
  > | updated_at                  | None                                                                   |
  > | client_ca_tls_container_ref | None                                                                   |
  > | client_authentication       | NONE                                                                   |
  > | client_crl_container_ref    | None                                                                   |
  > | allowed_cidrs               | None                                                                   |
  > | tls_ciphers                 |                                                                        |
  > | tls_versions                |                                                                        |
  > | alpn_protocols              |                                                                        |
  > | tags                        |                                                                        |
  > +-----------------------------+------------------------------------------------------------------------+
  > ```

- We create a pool for the HTTPS listener
- ⛔ **Note**: HTTP protocol is specified for pool because backends (members) are serving HTTP content on port 80.
```bash=
openstack loadbalancer pool create --name my-https-pool \
                                   --lb-algorithm ROUND_ROBIN \
                                   --listener my-https-listener \
                                   --protocol HTTP
```

  > ```bash=
  > root@ENG-DEV-OPS-01:/home/cuongdm3# openstack loadbalancer pool create --name my-https-pool \
  > >                                    --lb-algorithm ROUND_ROBIN \
  > >                                    --listener my-https-listener \
  > >                                    --protocol HTTP
  > +----------------------+--------------------------------------+
  > | Field                | Value                                |
  > +----------------------+--------------------------------------+
  > | admin_state_up       | True                                 |
  > | created_at           | 2023-12-25T08:37:59                  |
  > | description          |                                      |
  > | healthmonitor_id     |                                      |
  > | id                   | 7c272655-18a3-4cbd-9ffe-24178280752f |
  > | lb_algorithm         | ROUND_ROBIN                          |
  > | listeners            | be04de0f-5db3-47b6-b224-f6ed22034830 |
  > | loadbalancers        | b1ab8cbd-96ce-4a77-8471-f6d9d3ace115 |
  > | members              |                                      |
  > | name                 | my-https-pool                        |
  > | operating_status     | OFFLINE                              |
  > | project_id           | c430b410b86f412194999216f04ec39a     |
  > | protocol             | HTTP                                 |
  > | provisioning_status  | PENDING_CREATE                       |
  > | session_persistence  | None                                 |
  > | updated_at           | None                                 |
  > | tls_container_ref    | None                                 |
  > | ca_tls_container_ref | None                                 |
  > | crl_container_ref    | None                                 |
  > | tls_enabled          | False                                |
  > | tls_ciphers          |                                      |
  > | tls_versions         |                                      |
  > | tags                 |                                      |
  > | alpn_protocols       |                                      |
  > +----------------------+--------------------------------------+
  > ```

- Finally we add our 2 backend VMs

```bash=
openstack loadbalancer member create --subnet-id mysubnet --address 10.10.10.167 --protocol-port 80 my-https-pool
openstack loadbalancer member create --subnet-id mysubnet --address 10.10.10.187 --protocol-port 80 my-https-pool
```

  > ```bash=
  > root@ENG-DEV-OPS-01:/home/cuongdm3# openstack loadbalancer member create --subnet-id mysubnet --address 10.10.10.167 --protocol-port 80 my-https-pool
  > +---------------------+--------------------------------------+
  > | Field               | Value                                |
  > +---------------------+--------------------------------------+
  > | address             | 10.10.10.167                         |
  > | admin_state_up      | True                                 |
  > | created_at          | 2023-12-25T08:39:26                  |
  > | id                  | d58de3b7-d931-4578-8f63-4d739f5d2d80 |
  > | name                |                                      |
  > | operating_status    | NO_MONITOR                           |
  > | project_id          | c430b410b86f412194999216f04ec39a     |
  > | protocol_port       | 80                                   |
  > | provisioning_status | PENDING_CREATE                       |
  > | subnet_id           | cdae1465-0666-42f3-b060-9fbaa02d38a3 |
  > | updated_at          | None                                 |
  > | weight              | 1                                    |
  > | monitor_port        | None                                 |
  > | monitor_address     | None                                 |
  > | backup              | False                                |
  > | tags                |                                      |
  > +---------------------+--------------------------------------+
  > root@ENG-DEV-OPS-01:/home/cuongdm3# openstack loadbalancer member create --subnet-id mysubnet --address 10.10.10.187 --protocol-port 80 my-https-pool
  > +---------------------+--------------------------------------+
  > | Field               | Value                                |
  > +---------------------+--------------------------------------+
  > | address             | 10.10.10.187                         |
  > | admin_state_up      | True                                 |
  > | created_at          | 2023-12-25T08:39:38                  |
  > | id                  | ef61aed8-50ba-4fde-b7cc-e94b1bbcf4a5 |
  > | name                |                                      |
  > | operating_status    | NO_MONITOR                           |
  > | project_id          | c430b410b86f412194999216f04ec39a     |
  > | protocol_port       | 80                                   |
  > | provisioning_status | PENDING_CREATE                       |
  > | subnet_id           | cdae1465-0666-42f3-b060-9fbaa02d38a3 |
  > | updated_at          | None                                 |
  > | weight              | 1                                    |
  > | monitor_port        | None                                 |
  > | monitor_address     | None                                 |
  > | backup              | False                                |
  > | tags                |                                      |
  > +---------------------+--------------------------------------+
  > ```

- Check the loadbalancer `myloadbalancer-01` again, it now has 4 listeners and 4 pools:
```bash=
openstack loadbalancer show myloadbalancer-01
```

  > ```bash=
  > root@ENG-DEV-OPS-01:/home/cuongdm3# openstack loadbalancer show myloadbalancer-01
  > +---------------------+--------------------------------------+
  > | Field               | Value                                |
  > +---------------------+--------------------------------------+
  > | admin_state_up      | True                                 |
  > | availability_zone   |                                      |
  > | created_at          | 2023-12-25T05:50:19                  |
  > | description         |                                      |
  > | flavor_id           | None                                 |
  > | id                  | b1ab8cbd-96ce-4a77-8471-f6d9d3ace115 |
  > | listeners           | 0248e8f4-126c-4c36-8a89-0f89c2a96f51 |
  > |                     | 21f36ab9-af77-4d81-a4b4-1285845e94e8 |
  > |                     | a72c0566-5de8-40d3-a02c-0db19c0c543a |
  > |                     | be04de0f-5db3-47b6-b224-f6ed22034830 |
  > | name                | myloadbalancer-01                    |
  > | operating_status    | OFFLINE                              |
  > | pools               | 67855985-3ea6-4452-81b4-33a8d04f276a |
  > |                     | 7c272655-18a3-4cbd-9ffe-24178280752f |
  > |                     | 8579b7de-46bb-4218-85f5-3ab3e7bce370 |
  > |                     | b65b8dea-27df-4937-834e-f3c97bb9d60b |
  > | project_id          | c430b410b86f412194999216f04ec39a     |
  > | provider            | amphora                              |
  > | provisioning_status | ACTIVE                               |
  > | updated_at          | 2023-12-25T08:39:41                  |
  > | vip_address         | 49.213.90.199                        |
  > | vip_network_id      | 4688a041-4945-44e8-8d2e-f95de42d50b1 |
  > | vip_port_id         | 3c4d6981-855f-4ce5-a7db-186b22fa22fe |
  > | vip_qos_policy_id   | None                                 |
  > | vip_subnet_id       | 701d61f7-799e-4ee5-8c9a-b6eba6dcd33c |
  > | tags                |                                      |
  > | additional_vips     |                                      |
  > +---------------------+--------------------------------------+
  > ```

- Last step is to verify ssl termination. loadbalancer's virtual IP can be found by executing openstack loadbalancer list.
- Open a browser and check https://49.213.90.199 or run:
```bash=
curl -k https://49.213.90.199
```

  > ```bash=
  > root@ENG-DEV-OPS-01:/home/cuongdm3# curl -k https://49.213.90.199
  > <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
  > <html xmlns="http://www.w3.org/1999/xhtml">
  >   <!--
  >     Modified from the Debian original for Ubuntu
  >     Last updated: 2022-03-22
  >     See: https://launchpad.net/bugs/1966004
  >   -->
  >   <head>
  >     <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
  >     <title>Apache2 Ubuntu Default Page: It works</title>
  >     <style type="text/css" media="screen">
  >   * {
  >     margin: 0px 0px 0px 0px;
  >     padding: 0px 0px 0px 0px;
  >   }
  > 
  >   body, html {
  >     padding: 3px 3px 3px 3px;
  > 
  >     background-color: #D8DBE2;
  > 
  >     font-family: Ubuntu, Verdana, sans-serif;
  > ...
  > ```

- You can print statistics about your loadbalancer using:
```bash=
openstack loadbalancer stats show myloadbalancer-01
```
  > ```bash=
  > root@ENG-DEV-OPS-01:/home/cuongdm3# openstack loadbalancer stats show myloadbalancer-01
  > +--------------------+-------+
  > | Field              | Value |
  > +--------------------+-------+
  > | active_connections | 0     |
  > | bytes_in           | 0     |
  > | bytes_out          | 0     |
  > | request_errors     | 0     |
  > | total_connections  | 0     |
  > +--------------------+-------+
  > ```