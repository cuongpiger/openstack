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