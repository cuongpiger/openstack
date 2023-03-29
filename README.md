# 1. Prepare the environment
* Using `multipass` to create the environment:
  ```bash
  # workdir: here
  multipass launch -n openstack -c 4 -m 6G -d 20G --mount ./:/devstack 20.04
  multipass shell openstack
  ```
  
# 2. Install OpenStack
* **Note**: Entire the below commands are executed inside the `openstack` VM.
* Create the `stack` user.
  ```bash
  # workdir: /devstack
  sudo ./tools/create-stack-user.sh
  ```
    * Verify that `stack` user is created.
      ```bash
      # workdir: /devstack
      id stack
      ```
    * Verify that `stack` user is in the `stack` group _(also check that group `stack` is created)_.
      ```bash
      # workdir: /devstack
      groups stack
      ```
* Switch to `stack` user.
  ```bash
  # workdir: /devstack
  sudo su - stack
  ```
* [Optional] Alias for testing.
  ```bash
  function stackall() {
    cd /devstack && clear && ./stack.sh
  }
  
  function unstackall() {
    cd /devstack && clear && ./unstack.sh && ./clean.sh
  }
  ```
* Run `stack.sh` script.
  ```bash
  # workdir: /devstack
  ./stack.sh
  ```