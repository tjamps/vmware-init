#!/bin/bash

function exit_failure {
    if [ "$1" ]; then
        echo -e "\e[31mError: $1\e[0m"
    fi
    exit 1
}

function is_os_ubuntu {
    command -v lsb_relase > /dev/null 2>&1 || return 1
    lbs_release -a | grep -i ubuntu > /dev/null 2>&1 && return 0
    
    return 1
}

function is_user_root {
    id -un | grep root > /dev/null 2>&1 && return 0
    return 1
}

if ! is_os_ubuntu; then
    exit_failure "This script is only intended to be run on Ubuntu GNU/Linux."
fi

if ! is_user_root; then
    exit_failure "You must be root to execute this script (sudo -i)."
fi

