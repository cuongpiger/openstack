#!/bin/bash

# Prepare the multipass VM and login to its shell.
# This function is used at host machine.
function run_multipass() {
  multipass launch -n keystone -c 6 -m 8G -d 100G --mount ./:/devstack 20.04 && \
  multipass shell keystone
}

# Delete the VM and purge the data.
# This function is used at host machine.
function del_multipass() {
  multipass delete keystone && multipass purge
}