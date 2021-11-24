---
layout: post
title:  "Running a Kubernetes native x86_64 application on Raspberry Pis, and why you shouldn't!"
date:   2021-11-28 14:00:00
categories: [Kubernetes,  QEMU]
---
# Running a Kubernetes native x86_64 application on Raspberry Pis, and why you shouldn't!

While this guide does work, don't do this. Emulation is *slow* and Raspberry Pi CPUs (even overclocked to 2GHz) are slower!

Also, you have to use x86_64 emulation (rather than KVM) because Pis use an ARM instruction set rather than x86.

# CPU benchmark for slowness
This benchmark is terrible, but gives an indication of single threaded performance

# On my macbook
```bash
#On my work machine
time dd if=/dev/urandom of=/dev/null bs=2000000 count=100

real	0m4.264s
user	0m0.000s
sys	0m4.264s (edited)

# On a VM on k3s-005
$ time dd if=/dev/urandom of=/dev/null bs=2000000 count=100

real 0m 19.08s
user 0m 0.03s
sys 0m 18.94s

# Natively on that Pi
pi@node-005:~ $ time dd if=/dev/urandom of=/dev/null bs=2000000 count=100

real	0m2.784s
user	0m0.004s
sys	0m2.769s
```


## Architecture

<div align="center">x86_64 Application</div>

<div align="center">Kubernetes (k3s)</div>

<div align="center">QEMU x86_64 emulation</div>

<div align="center">Raspberry Pis</div>

# Equipment in use
* 4 * Pi 4 8GB
* SSD enclosure per Pi
* SSD per Pi
* Ethernet switch
* A router
* Power
* misc cables

## OSs in use
* Raspbian 64 bit on the Pis
* Alpine in the x86_64 VMs

## Setting up the Pis

We installed 64 bit Raspbian on the SSDs and booted from them.

### Installing the dependencies

```bash
sudo apt update && sudo apt upgrade -y && sudo apt install -y qemu nmon virtinst qemu-utils qemu-system-x86 tmux vim dnsmasq-utils dnsmasq-base iptables libvirt-daemon-system
```

### Setting up the QEMU groups

```bash
groupadd libvirt-qemu
groupadd libvirt
groupadd libvirtd
useradd -g libvirt-qemu libvirt-qemu
```

### Setting up swap (in case it's need since 8GB RAM isn't much)

```bash
# Create and mount swap
sudo fallocate -l 64G /swapfile && sudo chmod 600 /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile
```
Next add an entry to fstab so that the swap is mounted on boot.
```bash
sudo su -c "echo '/swapfile swap swap defaults 0 0' >> /etc/fstab"
```

### Setting up the Bridge networking so the VMs can connect directly (helpful for k8s)
Largely following <https://www.raspberrypi.com/documentation/computers/configuration.html#bridging>
```bash
sudo su -c "echo '[NetDev]
Name=br0
Kind=bridge
' >> /etc/systemd/network/bridge-br0.netdev"

sudo su -c "echo '[Match]
Name=eth0

[Network]
Bridge=br0
' >> /etc/systemd/network/bridge-br0.netdev"
sudo systemctl enable systemd-networkd

```
Next ensure that eth0 is on the bridge network, and it's the bridge that does dhcp rather than other interfaces

```bash
sudo vim /etc/dhcpcd.conf
# At top add the following, without the #
# denyinterfaces wlan0 eth0

# at the very bottom add, without the #
# interface br0

```
Next is to let QEMU use this bridge, largely following <https://wiki.archlinux.org/title/QEMU#Bridged_networking_using_qemu-bridge-helper>


```bash

```

