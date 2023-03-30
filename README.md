# 1. Prepare the environment

- Alias for the below commands at host machine.

  ```bash
  # Prepare the multipass VM and login to its shell.
  # This function is used at host machine.
  function run_multipass() {
    multipass launch -n openstack -c 4 -m 6G -d 20G --mount ./:/devstack 20.04 && \
    multipass shell openstack
  }

  # Delete the VM and purge the data.
  # This function is used at host machine.
  function del_multipass() {
    multipass delete openstack && multipass purge
  }
  ```

- Run the below command at host machine to start the multipass VM.
  ```bash
  run_multipass
  ```
- Inside the `openstack` VM, alias for the below functions:

  ```bash
  # Install and run the OpenStack cloud.
  function stack_all() {
    cd /devstack && clear && ./stack.sh
  }

  # Unstack and clean the OpenStack installation.
  function unstack_all() {
    cd /devstack && clear && ./unstack.sh && ./clean.sh
  }

  # Create the `stack` user.
  function create_stack_user() {
    sudo /devstack/tools/create-stack-user.sh
  }

  # Switch to `stack` user.
  function switch_to_stack_user() {
    sudo su - stack
  }
  ```

# 2. Install OpenStack

- **Note**: Entire the below commands are executed inside the `openstack` VM.
- Create the `stack` user.

  ```bash
  create_stack_user
  ```

  - [Optional] Verify that `stack` user is created.
    ```bash
    id stack
    ```
  - [Optional] Verify that `stack` user is in the `stack` group _(also check that group `stack` is created)_.
    ```bash
    groups stack
    ```

- Switch to `stack` user.
  ```bash
  switch_to_stack_user
  ```
- Install and run the OpenStack cloud.
  ```bash
  stack_all
  ```
