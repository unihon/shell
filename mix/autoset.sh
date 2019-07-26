#!/bin/bash

# ------------------------------------------------------
# 测试系统：CentOS Linux release 7.6.1810 (Core)
# 服务配置以作业内容为主
# 软件的不同版本的配置文件可能不一样
# samba 4.8.3
# bind 9.9.4
# bind-chroot 9.9.4
# httpd 2.4.6
# ------------------------------------------------------

ISSUE_FILE="/etc/issue"
RELEASE_FILE="/etc/*-release"
OS_FILE="/etc/redhat-release"

PACK_SAMBA="samba"
PACK_BIND="bind"
PACK_BIND_CHROOT="bind-chroot"
PACK_HTTPD="httpd"

PACKS=($PACK_SAMBA $PACK_BIND $PACK_BIND_CHROOT $PACK_HTTPD)

messOutPut(){
	echo -e "\n+<-----------------------------------------------------------+"
	echo -e " $@"
	echo -e "+----------------------------------------------------------->+\n"

	return 0
}

# 系统版本检查
osCheck(){
	if [ $(sed -r 's/.*\s([0-9]+).*/\1/' ${OS_FILE}) -ne 7 ]; then
		messOutPut "脚本只用于 CentOS 7"
		exit
	fi

	return 0
}

# 发行版本检查
getDist(){
	if grep -iq "centos" $ISSUE_FILE $RELEASE_FILE; then
		osCheck
	else
		messOutPut "脚本只用于 CentOS 发行版本"
		exit
	fi
	messOutPut "系统信息正确"

	return 0
}

# SElinux 检查
selinuxCheck(){
	if [ "$(getenforce)" == "Enforcing" ]; then
		messOutPut "当前 SElinux 模式为 Enforcing，将切换为 Permissive 模式"
		setenforce 0
		sed -r -i 's/(SELINUX=)enforcing$/\1permissive/' /etc/selinux/config
	fi

	return 0
}

# 软件包检查
checkPack(){
	messOutPut "软件状态检查..."
	for i in "${PACKS[@]}"
	do
		rpm -qa | egrep -q "^${i}-[0-9]" || return 1
	done

	return 0
}

# 安装软件包
installPack(){
	messOutPut "软件安装列表:\n\n" "${PACKS[@]}"
	read -p "> 确认安装？[y/n]: " ikey
	echo
	[ "$ikey" != "y" ] && exit

	yum -y install ${PACKS[@]}

	if ! checkPack; then
		read -p "> 软件未完全安装，是否重新安装，如果否，则将退出脚本？[y/n]: " ikey
		echo
		[ "$ikey" != "y" ] && exit 
		installPack
	fi

	messOutPut "完成软件安装！"

	return 0
}

# 防火墙设置
firewallSet(){
	if systemctl -q is-active firewalld.service; then
		firewall-cmd --add-port=${1} --permanent
		firewall-cmd --reload
	fi

	return 0
}

# 软件配置
sambaConf(){
	messOutPut "开始配置 samba"
	smb_conf="/etc/samba/smb.conf"

	# samba 用户设置
	smbuser="smbuser"
	smbuser_passwd="1"
	useradd $smbuser -s /sbin/nologin
	echo -e "${smbuser_passwd}\n${smbuser_passwd}" | smbpasswd -as $smbuser

	# 设置共享目录
	mkdir -p /share
	chmod 777 /share 
	echo "test" > /share/test.txt

	# 设置 samba 配置文件
	# 工作组
	sed -r -i 's/(workgroup\s=\s).*/\1Workgroup/' $smb_conf
	# 分享名
	sed -r -i 's/\[homes\]/\[public\]/' $smb_conf
	# 备注
	sed -r -i 's/(comment\s=\s)Home(\s.*)/\1Public\2/' $smb_conf
	# 分享目录
	sed -r -i '/(comment\s=\s)Public(\s.*)/a\\tpath = /share' $smb_conf
	# 允许所有用户
	sed -r -i '/valid\susers/d' $smb_conf
	# 允许浏览目录
	sed -r -i 's/(browseable\s=\s).*/\1Yes/' $smb_conf

	# samba 端口
	messOutPut "开放 samba 端口"
	firewallSet '137-139/tcp'
	firewallSet '445/tcp'

	messOutPut "samba 配置完成！\n\n" "用户名：smbuser\n 密码：1\n\n 共享目录：/share\n 工作组：Workgroup\n 共享名：public"

	read -p "> 现在启动 samba 并设置自动启动？[y/n]: " ikey
	echo
	[ "$ikey" == "y" ] && systemctl enable smb &> /dev/null && systemctl start smb

	return 0
}

bindConf(){
	messOutPut "开始配置 bind"
	zone_etc="/var/named/chroot/etc/"
	zone_dir="/var/named/chroot/var/named/"
	zone_file="jnrp.cn.zone"
	zone_refile="168.192.zone"

	# 设置 bind 主配置文件
	# 不能直接用 sed 写入到 chroot 内的文件
	sed -r -i 's/(listen-on\sport\s53).*/\1 \{ any; \};/' /etc/named.conf
	sed -r -i 's/(listen-on-v6\sport\s53).*/\1 \{ any; \};/' /etc/named.conf
	sed -r -i 's/(allow-query).*/\1 \{ any; \};/' /etc/named.conf

	/usr/libexec/setup-named-chroot.sh /var/named/chroot on

	# 根据作业需求配置
	cat >> ${zone_etc}named.rfc1912.zones << EFO
zone "jnrp.cn" IN {
	type master;
	file "jnrp.cn.zone";
};

zone "168.192.in-addr.arpa" IN {
	type master;
	file "168.192.zone";
};
EFO

	# 正向解析
	cat > ${zone_dir}${zone_file} << EFO
\$TTL 1D
@	IN SOA	dns.jnrp.cn. mail.jnrp.cn. (
					0	; serial
					1D	; refresh
					1H	; retry
					1W	; expire
					3H )	; minimum
	NS	@
	A	127.0.0.1
	AAAA	::1
@   IN  NS  dns.jnrp.cn.
@   IN  MX  10  mail.jnrp.cn.
dns IN  A   192.168.1.2
mail    IN  A   192.168.0.3 
slave   IN  A   192.168.1.4
www IN  A   192.168.0.5
forward IN  A   192.168.0.6
computer    IN  A   192.168.22.98
ftp IN  A   192.168.0.11
stu IN  A   192.168.21.22
web IN  CNAME   www.jnrp.cn.
EFO

	# 反向解析
	cat > ${zone_dir}${zone_refile} << EFO
\$TTL 1D
@	IN SOA	dns.jnrp.cn. mail.jnrp.cn. (
					0	; serial
					1D	; refresh
					1H	; retry
					1W	; expire
					3H )	; minimum
	NS	@
	A	127.0.0.1
	AAAA	::1
2.1 IN  PTR dns.jnrp.cn. 
3.0 IN  PTR mail.jnrp.cn.
4.1 IN  PTR slave.jnrp.cn.
5.0 IN  PTR www.jnrp.cn.
6.0 IN  PTR forward.jnrp.cn.
98.22   IN  PTR computer.jnrp.cn.
11.0    IN  PTR ftp.jnrp.cn.
22.21   IN  PTR stu.jnrp.cn.
EFO

	chgrp named ${zone_dir}${zone_refile} ${zone_dir}${zone_file}

	# 修改 dns
	sed -r -i '1,/nameserver/s/(nameserver\s).*/\1127.0.0.1/' /etc/resolv.conf

	# bind 端口
	messOutPut "开放 bind 端口"
	firewallSet '53/udp'

	messOutPut "bind 配置完成！"

	read -p "> 现在启动 bind 并设置自动启动？[y/n]: " ikey
	echo
	[ "$ikey" == "y" ] && systemctl enable named-chroot &> /dev/null && systemctl start named-chroot

	return 0
}

httpdConf(){
	messOutPut "开始配置 apache"
	httpd_userdir="/etc/httpd/conf.d/userdir.conf"
	# 根据作业需求配置

	# 增加测试用户
	http_user="long"
	useradd $http_user
	echo "1" | passwd --stdin $http_user

	# 在测试用户家目录创建 http 文件
	chmod 755 /home/${http_user}
	mkdir -p /home/${http_user}/public_html
	echo "<h1>Hello ${http_user}!</h1>" > /home/${http_user}/public_html/index.html

	# 设置 httpd userdir 配置文件
	sed -r -i 's/(UserDir\sdisabled$)/\1 root/' $httpd_userdir
	sed -r -i 's/#(UserDir\spublic_html$)/\1/' $httpd_userdir

	# httpd 端口
	messOutPut "开放 apache 端口"
	firewallSet '80/tcp'

	messOutPut "apache 配置完成！\n\n" "测试用户：long\n" "示例：http://127.0.0.1/~${http_user}"

	read -p "> 现在启动 apache 并设置自动启动？[y/n]: " ikey
	echo
	[ "$ikey" == "y" ] && systemctl enable httpd &> /dev/null && systemctl start httpd

	return 0
}

# ---------------------------------

# 发行版本检查
getDist
# SElinux 检查
selinuxCheck
# 安装软件包
installPack
sambaConf
bindConf
httpdConf

messOutPut "完成配置！"
