#!/usr/bin/env bash

function create_stack_user {
    sudo useradd -s /bin/bash -d /opt/stack -m stack && \
    sudo chmod +x /opt/stack && \
    echo "stack ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/stack
}

function switch_to_stack_user {
    sudo -u stack -i
}
