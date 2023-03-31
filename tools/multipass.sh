#!/bin/bash

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