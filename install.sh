#!/bin/bash
echo "脚本作者:火星小刘 web:www.huoxingxiaoliu.com email:xtlyk@163.com "
echo "Script author:mars web:www.huoxingxiaoliu.com email:xtlyk@163.com "
echo "###特别感谢一下朋友的大力支持"
echo "瑞金童鞋"
echo "@河南-孤鹰"
echo "广州-tiger"
sleep 3

echo "Have you read the readme.txt?"
read -p  "please input (y\n):" isY
if [ "${isY}" != "y" ] && [ "${isY}" != "Y" ];then   
exit 1
fi

#yum update -y
nagiosdir=`pwd`
ip=$(ifconfig | grep "inet addr" | grep -v 127.0.0.1 | awk '{print $2}' | awk -F ':' '{print $2}')
echo "Current directory:$nagiosdir"
echo "localhost:$ip"
echo "先安装相关组件"
echo "install php httpd"
sleep 2
yum install -y wget httpd php php-devel php-gd gcc glibc glibc-common gd gd-devel make net-snmp

echo "install nagios-4.0.8"
sleep 2
wget http://jaist.dl.sourceforge.net/project/nagios/nagios-4.x/nagios-4.0.8/nagios-4.0.8.tar.gz
tar zxvf nagios-4.0.8.tar.gz

#add user and group
useradd nagios
groupadd nagcmd
usermod -a -G nagcmd nagios

cd nagios-4.0.8

./configure --prefix=/usr/local/nagios --with-command-group=nagcmd --with-nagios-group=nagcmd

make all
make install 
make install-init  
make install-config 
make install-commandmode 
make install-webconf 

cp -R contrib/eventhandlers/ /usr/local/nagios/libexec/

chown -R nagios:nagcmd /usr/local/nagios/libexec/eventhandlers

/usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg

service nagios start
cd ..

echo "set httpd"
sleep 2

sed -i 's/User\ apache/User\ nagios/g' /etc/httpd/conf/httpd.conf
sed -i 's/Group\ apache/Group\ nagcmd/g' /etc/httpd/conf/httpd.conf

echo "ServerName nagios" >> /etc/httpd/conf/httpd.conf

echo "nagios web登陆用户名为nagiosadmin，请输入密码"
echo "nagios web username:nagiosadmin，pleas input password"

htpasswd -c /usr/local/nagios/etc/htpasswd.users nagiosadmin

echo "安装nagios-plugins"

echo "install nagios-plugins"
sleep 2
wget http://nagios-plugins.org/download/nagios-plugins-2.0.3.tar.gz
tar zxvf nagios-plugins-2.0.3.tar.gz

cd nagios-plugins-2.0.3

./configure --prefix=/usr/local/nagios --with-nagios-user=nagios --with-nagios-group=nagcmd --with-command-user=nagios --with-command-group=nagcmd
make
make install
cd ..


echo "为nagios安装图表pnp4nagios"
echo "install pnp4nagios"
sleep 2
wget http://jaist.dl.sourceforge.net/project/pnp4nagios/PNP-0.6/pnp4nagios-0.6.24.tar.gz
yum install -y perl-Time-HiRes rrdtool  rrdtool-perl
#wget http://jaist.dl.sourceforge.net/project/pnp4nagios/PNP-0.6/pnp4nagios-0.6.24.tar.gz
tar zxvf pnp4nagios-0.6.24.tar.gz

cd pnp4nagios-0.6.24
./configure --prefix=/usr/local/pnp4nagios/ --with-nagios-user=nagios --with-nagios-group=nagcmd
make all
make install
make install-webconf
make install-config
make install-init

cd /usr/local/pnp4nagios/etc/
mv misccommands.cfg-sample misccommands.cfg
mv nagios.cfg-sample nagios.cfg
mv rra.cfg-sample rra.cfg
cd pages
mv web_traffic.cfg-sample web_traffic.cfg
cd ../check_commands
mv check_all_local_disks.cfg-sample check_all_local_disks.cfg
mv check_nrpe.cfg-sample check_nrpe.cfg
mv check_nwstat.cfg-sample check_nwstat.cfg

cd $nagiosdir

#sed -i 's/process_performance_data=0/process_performance_data=1/g' /usr/local/nagios/etc/nagios.cfg
#sed -i 's/#host_perfdata_command=process-host-perfdata/host_perfdata_command=process-host-perfdata/g' /usr/local/nagios/etc/nagios.cfg
#sed -i 's/#service_perfdata_command=process-service-perfdata/service_perfdata_command=process-service-perfdata/g' /usr/local/nagios/etc/nagios.cfg

mv /usr/local/nagios/etc/objects/commands.cfg       /usr/local/nagios/etc/objects/commands.cfgbak

cp $nagiosdir/commands.cfg                          /usr/local/nagios/etc/objects/

mv /usr/local/nagios/etc/objects/templates.cfg      /usr/local/nagios/etc/objects/templates.cfgbak

cp $nagiosdir/templates.cfg                         /usr/local/nagios/etc/objects/

mv /usr/local/nagios/etc/nagios.cfg 		    /usr/local/nagios/etc/nagios.cfgbak

cp $nagiosdir/nagios.cfg 			    /usr/local/nagios/etc/

#sed -i 's/#service_perfdata_file=/usr/local/pnp4nagios/var/service-perfdata/service_perfdata_file=/usr/local/pnp4nagios/var/service-perfdata/g' /usr/local/nagios/etc/nagios.cfg

#sed -i 's/#service_perfdata_file=/usr/g' /usr/local/nagios/etc/nagios.cfg

mv /usr/local/pnp4nagios/share/install.php /usr/local/pnp4nagios/share/install.phpbak

chown nagios.nagcmd -R /usr/local/pnp4nagios/

chown nagios.nagcmd -R /usr/local/nagios/

chmod 777 -R /var/lib/php/session/


echo "邮件报警设置"
echo "install sendmail"
yum install -y mailx sendmail*




chkconfig sendmail on
service sendmail start
chkconfig httpd on
service httpd restart
chkconfig nagios on
service nagios restart
chkconfig npcd on
service npcd restart

echo "安装结束，请按照readme.txt设置发送邮箱地址。打开浏览器输入:http://$ip/nagios 访问"
echo "Success!But you have to "vi /etc/mail.rc" set smtp server like"set from=xtlyk@163.com smtp=smtp.163.com set smtp-auth-user=xtlyk@163.com smtp-auth-password=000000 smtp-auth=login"
echo "please open Browser Visit website:http://$ip/nagios"

echo " thinks from chinese mars.liu"

