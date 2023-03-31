#!/usr/bin/env bash

# Install and run the OpenStack cloud.
stack_all() {
  cd /devstack && clear && ./stack.sh
}

# Unstack and clean the OpenStack installation.
unstack_all() {
  cd /devstack && clear && ./unstack.sh && ./clean.sh
}

# Create the `stack` user.
create_stack_user() {
  sudo /devstack/tools/create-stack-user.sh
}

# Switch to `stack` user.
switch_to_stack_user() {
  sudo su - stack
}