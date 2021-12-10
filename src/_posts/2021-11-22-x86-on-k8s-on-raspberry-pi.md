---
layout: post
title:  "Running a Kubernetes native x86_64 application on Raspberry Pis, and why you shouldn't!"
date:   2021-12-08 19:00:00
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
* SSD enclosure per Pi supporting UASP
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

### Overclocking the Pis
The Raspberry Pi doesn't have the fastest CPU, so we overclocked it to 2GHz and over_voltage 6 to keep the warranty. Full guide <https://www.seeedstudio.com/blog/2020/02/12/how-to-safely-overclock-your-raspberry-pi-4-to-2-147ghz/>

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
Next check that trim works on the PI, if it's working you should get something similar to the following

```
sudo fstrim -av
/boot: 0 B (0 bytes) trimmed
/: 19.9 GiB (21294051328 bytes) trimmed
```
If this fails, you'll need to follow <https://www.jeffgeerling.com/blog/2020/enabling-trim-on-external-ssd-on-raspberry-pi>

Due to the high volume of writes expected since the SSD will be used as RAM, configure TRIM to run frequently to prevent rapid deterioration of the SSD.

```bash
# trimming every 2 min:
sudo vi /lib/systemd/system/fstrim.timer
# change:
[Timer]
OnCalender=*:0/2
AccuracySec=0

sudo systemctl daemon-reload
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
sudo mkdir /etc/qemu

# Add all that into a script (run as root):
#!bin/bash

cat <<EOT > /etc/systemd/network/bridge-br0.netdev
[NetDev]
Name=br0
Kind=bridge
EOT

cat <<EOT > /etc/systemd/network/br0-member-eth0.network
[Match]
Name=eth0

[Network]
Bridge=br0
EOT

sed -i '1s/^/denyinterfaces wlan0 eth0 \n/' /etc/dhcpcd.conf
echo "interface br0" >> /etc/dhcpcd.conf

if [[ ! -d "/etc/qemu" ]]; then
  mkdir /etc/qemu
fi
echo "allow br0" > /etc/qemu/bridge.conf


#then need to execute later
systemctl enable system-networkd

```

### Running the x86 VM
For the VM we used Alpine as it's a light OS and compatible with k3s. You can choose your download from <https://alpinelinux.org/downloads/>

```bash
wget https://dl-cdn.alpinelinux.org/alpine/v3.15/releases/x86_64/alpine-virt-3.15.0-x86_64.iso
```
Next you'll have to create a disk image for the Alpine VM, we created a 128GB sparse image given the size of the SSDs we used.

```bash
qemu-img create -f qcow2 alpine.qcow2 128G

```

Now to run the VM, this command must be run from a display because it attempts to open a window. It is possible to do this in a headless fashion, but we couldn't get that working.
Each VM needs a unique mac address for the networking to work correctly

```bash
sudo qemu-system-x86_64 --name alpine-node -drive file=/home/pi/alpine.qcow2 -smp cpus=4 -m 60G,slots=4,maxmem=61G -accel tcg,thread=multi -nic bridge,br=br0,model=virtio-net-pci,mac=52:54:00:12:34:50
```
Exciting options, 
`-accel tcg,thread=multi` enables the VM to use multiple host cores
`virtio-net-pci` allows a virtual nic that works with the bridge configured.

You should ensure each of these VMs have a unique hostname, and a static IP in your router. This will make k3s configuration much easier


## Configuring k3s
For our setup, one Pi ran the k3s control plane natively (and didn't have a VM running) and the other Pis each had a VM running. Those VMs were joined to the k3s cluster as worker nodes.

Before installing on the control node, follow <https://rancher.com/docs/k3s/latest/en/advanced/#enabling-legacy-iptables-on-raspbian-buster> to set up iptables correctly and <https://rancher.com/docs/k3s/latest/en/advanced/#enabling-cgroups-for-raspbian-buster> to set up cgroups correctly.

Before installing on the (virtual) worker nodes, follow <https://rancher.com/docs/k3s/latest/en/advanced/#additional-preparation-for-alpine-linux-setup>

### Installing the control-plane

Unfortunately, the easiest way to install k3s with systemd is running random scripts from the internet...

```bash

sudo -i
apt install -y curl
curl -sfL https://get.k3s.io | sh -
```

## Prevent pods running on control plane
It's generally a bad idea to run workloads on your control plane, especially in this case as our workloads with be x86 but the control plane is ARM64.

```bash
kubectl taint nodes node-0001 node-role.kubernetes.io/master=true:NoSchedule
```

### Adding worker nodes
Pretty simple, [full guide here.](https://rancher.com/docs/k3s/latest/en/quick-start/#install-script)

```bash

apk add curl && curl -sfL https://get.k3s.io | K3S_URL=https://node-001:6443 K3S_TOKEN=SomeTokenFromControlPlane sh -
```

With this, the x86_64 workers nodes should be added the cluster. 

## Success?
If you're successful, you should have a working k3s cluster with workloads running on x86 (slowly!)

```bash
pi@node-001:~ $ kubectl get nodes
NAME                            STATUS   ROLES                  AGE    VERSION
node-001                        Ready    control-plane,master   105m   v1.21.5+k3s2
k3s-002                         Ready    control-plane,master   100m   v1.21.5+k3s2
k3s-003                         Ready    control-plane,master   90m   v1.21.5+k3s2
k3s-004                         Ready    control-plane,master   80m   v1.21.5+k3s2
k3s-005                         Ready    control-plane,master   70m   v1.21.5+k3s2
```
## Why you shouldn't do this

Over 1.5 cores of the Pi is used by *k3s*, never mind the workloads we want to run!

Here's a simple [pod](https://github.com/reactive-tech/kubegres) which didn't manage to start, even after 5 mins due to the CPU limitations.

```bash
pi@node-001:~ $ kubectl get pod -w
NAME                                              READY   STATUS              RESTARTS   AGE
kubegres-controller-manager-75b6765589-kvr97      1/2     ContainerCreating   0          4m54s
```

## Conclusions
Don't run x86 on Pis, especially not on kubernetes! They just aren't fast enough (yet)
