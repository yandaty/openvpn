#!/bin/bash
cp epel.repo /etc/yum.repos.d/
 
setenforce  0
#添加yum源
yum install -y epel-release --nogpgcheck
#关闭selinux
sed -i s/SELINUX=enforcing/SELINUX=disabled/g /etc/selinux/config 
#更新系统包
#安装openvpn需要的包
yum install -y openssl lzo pam openssl-devel lzo-devel pam-devel easy-rsa openvpn --nogpgcheck
#拷贝证书生成文件, 因yum安装最新包，如果变动需要将版本替换
cp vars /usr/share/easy-rsa/3.0.8/
cp server.conf /etc/openvpn/server/
\cp -f  openvpn-server\@.service /usr/lib/systemd/system/openvpn-server\@.service
cp -rf /usr/share/easy-rsa/3.0.8 /etc/openvpn/server/easy-rsa
cp -rf /usr/share/easy-rsa/3.0.8 /etc/openvpn/client/easy-rsa
#服务端证书跟key文件
cd /etc/openvpn/server/easy-rsa
./easyrsa init-pki
#创建根证书，
echo "输入根证书名称"
./easyrsa build-ca nopass
#创建服务端证书
echo "输入服务端证书名称"
./easyrsa gen-req server nopass
./easyrsa sign server server
./easyrsa gen-dh
#客户端证书跟key文件
cd /etc/openvpn/client/easy-rsa
./easyrsa init-pki
./easyrsa gen-req clientone nopass 
#进入server端添加客户端证书
cd /etc/openvpn/server/easy-rsa
./easyrsa  import-req /etc/openvpn/client/easy-rsa/pki/reqs/clientone.req clientone
./easyrsa sign client clientone
#关闭firewalld
systemctl  stop  firewalld
systemctl  disable   firewalld
#安装iptables
yum install -y iptables-services
systemctl enable iptables
systemctl start iptables   #启动iptables
iptables -F     #清空默认的iptables规则
iptables -t nat -A POSTROUTING -s 10.8.0.0/24  -j MASQUERADE     #设置iptables NAT转发规则
service iptables save   #保存防火墙规则
#开启路由转发
echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf
sysctl -p
#开启openvpn-server
systemctl start   openvpn-server@.service.service
systemctl enable   openvpn-server@.service.service
cp -f /etc/openvpn/server/easy-rsa/pki/issued/* /root/openvpn/
cp -f /etc/openvpn/server/easy-rsa/pki/ca.crt  /root/openvpn/
cp -f /etc/openvpn/client/easy-rsa/pki/private/* /root/openvpn/