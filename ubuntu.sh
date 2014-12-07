#!/bin/bash

function exit_failure {
    # Print red $1
    echo -e "\e[31mError: $1\e[0m"
    exit 1
}

function print_info {
    # Print bold white $1
    echo -e "\e[1;37m+ $1\e[0m"
}

function print_variable_info {
    # $1 : Label to display
    # $2 : Variable to display
    echo -ne "\e[1;37m+ $1 : \e[0m"
    echo -e  "\e[36m $2\e[0m"
}

function is_os_ubuntu {
    # Check if command exists.
    command -v lsb_release > /dev/null 2>&1 || return 1
    (lsb_release -a | grep -i ubuntu) > /dev/null 2>&1 && return 0
    
    return 1
}

function is_user_root {
    id -un | grep root > /dev/null 2>&1 && return 0
    return 1
}

function is_vmware {
    (dmidecode -s system-product-name | grep -i vmware) > /dev/null 2>&1 && return 0
    return 1
}

function get_current_ip {
    ip -o -4 addr show eth0 | awk '{ print $4; }' | cut -d/ -f1
}

function set_static_ip {
    local current_ip=$(get_current_ip)
    # Search for default VMware gateway ;)
    local current_gw=$(echo $current_ip | cut -d. -f1-3).2
    
    mv /etc/network/interfaces /etc/network/interfaces.bak
    cat << EOF > /etc/network/interfaces
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
auto eth0
iface eth0 inet static
    address $current_ip
    netmask 255.255.255.0
    gateway $current_gw
    dns-nameservers $current_gw
EOF
}

function restart_networking {
    ifdown eth0 && ifup eth1 && return 0
    return 1
}

###############################################################################
# MAIN
###############################################################################

if ! is_os_ubuntu; then
    exit_failure "This script is only intended to be run on Ubuntu GNU/Linux."
fi

if ! is_user_root; then
    exit_failure "You must be root to execute this script (sudo -i)."
fi

if ! is_vmware; then
    exit_failure "This script is only intended to be run on VMware virtual machines."
fi

# Fix IP address
print_info "Setting static IP address..."

print_variable_info "Detected IP address" $(get_current_ip)

set_static_ip

print_info "Restart networking..."
if ! restart_networking; then
    exit_failure "Network could not be restarted."
fi

print_info "Static IP address set."

