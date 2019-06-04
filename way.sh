#!/bin/sh
#Author: yangyongchao-ajz
#Function: get server system information 

yum install dmidecode -y

VER=`cat /etc/redhat-release  | awk '{print $(NF-1)}'|awk -F. '{print $1}'`
if [ $VER -eq 6 ];then 
  netmac=`ifconfig |grep Ethernet | awk '{print $NF}'`
  netname=`ifconfig |grep Ethernet | awk '{print $1}'`
  netspeed=`ethtool  $netname | grep -oP "(?<=Speed:).*"`  
  netip=`ifconfig |grep -A 1 Ethernet |grep -oP "(?<= inet addr:)[\d.]+"`
  netmask=`ifconfig |grep -A 1 Ethernet |grep -oP "(?<=Mask:)[\d.]+"`
  tzone=`cat /etc/sysconfig/clock | awk -F= '{print $2}'`
  tlang=`cat  /etc/sysconfig/i18n  |grep -oP "(?<=LANG=).*"`
  firestatus=`service iptables status`
elif [ $VER -eq 7 ];then
  netname=`ifconfig |grep -C 3 ether |grep mtu |awk -F: '{print $1}'`
  netmac=`ifconfig |grep ether |awk '{print $2}'`
  netspeed=`ethtool  $netname | grep -oP "(?<=Speed:).*"`
  netip=`ifconfig |grep -B 3 ether |grep -oP "(?<=inet )[\d.]+"`
  netmask=`ifconfig |grep -B 3 ether |grep -oP "(?<=mask )[\d.]+"`
  tzone=`timedatectl status |grep -oP "(?<=Time zone:).*"`
  tlang=`cat /etc/locale.conf  |grep -oP "(?<=LANG=).*"`
  firestatus=`systemctl status firewalld |grep -oP "(?<=Active: )\S+\s\S+"`
fi
sysver=`cat /etc/redhat-release`
syscore=`uname -r`
dfroute=`route -n |grep UG | awk '{print $2}'`

cpucores=`cat /proc/cpuinfo| grep processor | wc -l`
cputype=`cat /proc/cpuinfo| grep "model name"| head -n 1| awk -F: '{print $2}'`
cpuvirt=`cat /proc/cpuinfo | egrep -o "vmx|svm"| head -n 1`

boadtype=`dmidecode | grep -A 10 "System Information" |grep Manufacturer | awk -F: '{print $2}'`
maxmem=`dmidecode |grep -A 10 "Physical Memory Array" |grep -oP "(?<=Maximum Capacity:).*"`
memnum=`dmidecode |grep -A 10 "Physical Memory Array" |grep -oP "(?<=Number Of Devices:).*"`


echo "----------------------------------------------------------------------------------------------"
echo "主机: $(hostname)"
echo "----------------------------------------------------------------------------------------------"
echo "硬件信息如下:"
echo "机器品牌: $boadtype"
echo "CPU型号: $cputype  核心数: $cpucores  是否支持虚拟化: $cpuvirt"
echo "内存插口数量: $memnum    最大支持内存容量: $maxmem"
dmidecode |grep -C 7 -P "\tLocator: " | grep -oP "(?<=\tLocator: ).*" | while read yyc
do
  memport=`dmidecode |grep -w -C 7 "Locator: $yyc" | grep -oP "(?<=Locator:).*" | head -n1`
  memsize=`dmidecode |grep -w -C 7 "Locator: $yyc" | grep -oP "(?<=Size:).*"`
  memtype1=`dmidecode |grep -w -C 7 "Locator: $yyc" | grep -oP "(?<=Manufacturer:).*"`
  memtype2=`dmidecode |grep -w -C 7 "Locator: $yyc" | grep -oP "(?<=Type:).*"`
  memspeed=`dmidecode |grep -w -C 7 "Locator: $yyc" | grep -oP "(?<=Speed:).*"`
  echo "接口${yyc}: 品牌 $memtype1 型号 $memtype2 速率 $memspeed 容量 $memsize"
done
echo "磁盘名称,ssd/hdd,容量,类型如下:"
lsblk -d -o name,rota,size,type  |egrep "disk|NAME"
echo "网卡信息:"
echo "网卡名称: $netname   网卡MAC: $netmac  网卡当前速率: $netspeed"

echo "----------------------------------------------------------------------------------------------"
echo "系统软件信息:"
echo "系统版本: $sysver   内核版本: $syscore"
echo "系统已启动天数: $(uptime)"
echo "时区: $tzone  语言: $tlang "
echo "IP地址: $netip   子网掩码: $netmask  默认网关: $dfroute "
echo "开放的端口:  $(netstat -utpln | grep tcp | awk '{print $4}'|awk -F: '{print $NF}'| sort |uniq -c | awk '{print $2}'| tr '\n' ',')"
echo "SELinux状态:  $(getenforce)"
echo "防火墙状态: "
echo "$firestatus"
echo ""
echo "磁盘挂载和使用信息:"
df -h |grep -v tmpfs
echo "----------------------------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------------------------"
echo ""
echo ""
echo "CPU使用率前三的进程:"
ps axo pid,ppid,user,stime,pcpu,pmem,cmd --sort -pcpu |  head -n 4
echo ""
echo "MEM使用率前三的进程:"
ps axo pid,ppid,user,stime,pcpu,pmem,cmd --sort -pmem |  head -n 4

