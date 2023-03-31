#!/usr/bin/env bash

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