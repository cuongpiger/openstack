# 1. Keystone with Redis OSProfiler
* Copy the config files:
  ```bash
  cp -r installation/keystone_redis/local.conf .
  cp -r installation/keystone_redis/stackrc .
  ```

* Run the Multipass env:
  ```bash
  source tools/multipass.sh
  run_multipass
  ```

* Run the installation:
  ```bash
  cd /devstack
  source tools/devstack.sh
  create_stack_user
  switch_to_stack_user

  cd /devstack
  source tools/devstack.sh
  stack_all
  ```

# 2. Keystone with Jaeger OSProfiler
* Copy the config files:
  ```bash
  cp -r installation/keystone_jaeger/local.conf .
  cp -r installation/keystone_jaeger/stackrc .
  ```

* Run the Multipass env:
  ```bash
  source tools/multipass.sh
  run_multipass
  ```

* Run the installation:
  ```bash
  cd /devstack
  source tools/devstack.sh
  create_stack_user
  switch_to_stack_user

  cd /devstack
  source tools/devstack.sh
  stack_all
  ```

## 2.1. Relevant things
* Go to this link to download the OpenRC file: 
  `http://<multipass vm host>/dashboard/project/api_access`

* The Jaeger UI is at:
  `http://<multipass vm host>:16686`

* Create new user in Keystone with tracing using CLI:
  ```bash
  openstack user create cuongdm3 --os-profile SECRET_KEY
  ```

* Exec the Docker command in the VM:
  ```bash
  sg docker -c '<docker command>'
  ```

* If you exited the Multipass VM previously, to use Jeager must be run this command before operating with OpenStack features:
  ```bash
  sg docker -c 'docker container start jaeger'
  ```