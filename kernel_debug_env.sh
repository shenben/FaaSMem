#!/bin/bash
function vm_image(){ #from tsinghua
    wget -O vmlinux https://cloud.tsinghua.edu.cn/f/ef649f94564e4b40a1c2/?dl=1 && \
    wget -O firecracker https://cloud.tsinghua.edu.cn/f/fa90c80489c842608a51/?dl=1 && \
    chmod +x vmlinux firecracker

    wget -O debian-nodejs-rootfs.ext4.zip https://cloud.tsinghua.edu.cn/f/0b2144137441475495a3/?dl=1 && \
    wget -O debian-python-rootfs.ext4.zip https://cloud.tsinghua.edu.cn/f/72ba9d8cdaac4abf8856/?dl=1
    sudo apt install unzip && unzip debian-nodejs-rootfs.ext4.zip && unzip debian-python-rootfs.ext4.zip
}

function single_tap(){
    ETH="eno3"
    tap_name="vmtap0"
    sudo ip tuntap add dev $tap_name mode tap user $USER
    sudo ip addr add 172.16.0.1/24 dev $tap_name
    sudo ip link set $tap_name up
    sudo sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
    sudo iptables -t nat -A POSTROUTING -o $ETH -j MASQUERADE
    sudo iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
    sudo iptables -A FORWARD -i $tap_name -o $ETH -j ACCEPT
}
function run_vm(){
    sudo rm -rf /tmp/firecracker.socket 
    # sudo ./firecracker --api-sock /tmp/firecracker.socket --config-file ./vm_config.json 
    # sudo ./firecracker-v1.12.0-x86_64 --api-sock /tmp/firecracker.socket --config-file ./vm_config.json 
    pushd /home/pxg/release-v1.7.0-x86_64
    sudo /home/pxg/release-v1.7.0-x86_64/firecracker-v1.7.0-x86_64 --api-sock /tmp/firecracker.socket --config-file ./vm_config.json 
    # # # inside VM
    # # ip addr add 172.16.0.2/24 dev eth0
    # # ip link set eth0 up
    # # ip route add default via 172.16.0.1 dev eth0
    # echo "nameserver 8.8.8.8" > /etc/resolv.conf 
    popd
}
function mk_image(){
    # for kernel compiling , 25GB space is enough.
    dd if=/dev/zero of=ubuntu22-minimal.ext4 bs=1G count=40
    mkfs.ext4 ubuntu22-minimal.ext4    
    sudo mkdir -p /mnt/ubuntu22
    sudo chmod 777 /mnt/ubuntu22 -R 
    sudo mount -o loop ubuntu22-minimal.ext4 /mnt/ubuntu22
   
    sudo apt update
    sudo apt install debootstrap
    sudo debootstrap --arch=amd64 jammy /mnt/ubuntu22 http://archive.ubuntu.com/ubuntu/

    # sudo chroot /mnt/ubuntu22
    # # echo "ubuntu22" > /etc/hostname
    # # echo "127.0.0.1 localhost" > /etc/hosts
    # # # passwd

    # # apt install linux-image-generic grub-pc systemd-sysv
    # # apt install -y libssl-dev libelf-dev libncurses-dev screen flex bison zip

}
run_vm
# vm_image
# single_tap