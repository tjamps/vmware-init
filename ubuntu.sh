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

function pause {
    read -r -n1 -s
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

###############################################################################
# NETWORKING
###############################################################################
function get_current_ip {
    ip -o -4 addr show eth0 | awk '{ print $4; }' | cut -d/ -f1
}

function set_static_ip {
    local current_ip=$(get_current_ip)
    # Search for default VMware gateway ;)
    local current_gw=$(echo "$current_ip" | cut -d. -f1-3).2
    
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
    ifdown eth0 && ifup eth0 && return 0
    return 1
}

###############################################################################
# UPGRADE
###############################################################################
function upgrade_machine {
    apt-get update > /dev/null 2>&1 || return 1
    apt-get upgrade -y > /dev/null 2>&1 || return 1
    return 0
}

###############################################################################
# VMWARE TOOLS
###############################################################################
function install_vmware_tools_dependencies {
    apt-get -y install build-essential linux-headers-"$(uname -r)" > /dev/null 2>&1 || return 1
    return 0
}

function mount_vmware_tools_disc {
    mount /dev/cdrom /media/cdrom > /dev/null 2>&1 && return 0
    return 1
}

function extract_vmware_tools_archive {
    tar xf /media/cdrom/VMwareTools*.tar.gz -C /tmp > /dev/null 2>&1 || return 1
    return 0
}

function install_vmware_tools {
    /tmp/vmware-tools-distrib/vmware-install.pl -d > "$1" 2>&1
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

print_variable_info "Detected IP address" "$(get_current_ip)"

set_static_ip

print_info "Restart networking..."
if ! restart_networking; then
    exit_failure "Network could not be restarted."
fi

print_info "Static IP address set."


# Upgrade machine
print_info "Upgrading machine..."
if ! upgrade_machine; then
    exit_failure "Machine could not be upgraded."
fi
print_info "Machine upgraded."


# VMware tools
print_info "Setting up VMware tools..."
print_info "Installing dependencies..."
if ! install_vmware_tools_dependencies; then
    exit_failure "Could not install VMware Tools dependencies."
fi
print_info "Dependencies installed."
print_info "You must now insert the VMware Tools installation disc. This can be done"
print_info "by clicking \"Virtual Machine > Install VMware Tools...\" in the menu."
print_info "Press any key when you're done."
pause
echo # For optics ;)

if ! mount_vmware_tools_disc; then
    exit_failure "VMware Tools disc could not be mounted."
fi
if ! extract_vmware_tools_archive; then
    exit_failure "VMware Tools archive could not be extracted."
fi
print_info "Installation log is available at /root/vmware-tools-install.log"
install_vmware_tools "/root/vmware-tools-install.log"


print_info "Seems all good ! You can reboot now :)"

exit 0