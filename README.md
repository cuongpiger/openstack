# 1. Keystone with Redis OSProfiler
* Copy the config files:
  ```bash
  cp -r installation/keystone_redis/local.conf .
  cp -r installation/keystone_redis/openrc .
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
  cp -r installation/keystone_jaeger/openrc .
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