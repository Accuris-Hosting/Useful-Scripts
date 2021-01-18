#!/bin/bash
clear
#Version : 4.1
#Check if all arguments have been specified
if [ $# -lt 6 ] ; then
   echo "You must specify all six arguments."
   exit 1
fi

# Parse command line options.
for i in $*
do
	case $i in 
	--mysql-username=*)
			user=`echo ${i#*=}`
			;;
	--mysql-password=*)
			pass=`echo ${i#*=}`
			;;
	--virt-serverip=*)
			master=`echo ${i#*=}`
			;;
	--masterns-ip=*)
	 		primarynsip=`echo ${i#*=}`
	 		;;
	 --slavens-ip=*)
	 		slaveip=`echo ${i#*=}`
	 		;;
	 --slavens-rootpass=*)
	 		slavepass=`echo ${i#*=}`
	 		;;
	 		
	 	esac
done

if [ ! -n "$user" ]; then
	 echo "Please enter the --mysql-username parameter"
	 exit 1
fi
if [ ! -n "$pass" ]; then
	 echo "Please enter the --mysql-password parameter"
	 exit 1
fi
if [ ! -n "$master" ]; then
	 echo "Please enter the --virt-serverip parameter"
	 exit 1
fi
if [ ! -n "$primarynsip" ]; then
	 echo "Please enter the --masterns-ip parameter"
	 exit 1
fi
if [ ! -n "$slaveip" ]; then
	 echo "Please enter the --slavens-ip parameter"
	 exit 1
fi
if [ ! -n "$slavepass" ]; then
	 echo "Please enter the --slavens-rootpass parameter"
	 exit 1
fi

setenforce 0 >> /dev/null 2>&1
LOG=/root/virtualizor-pdns.log

version=$( cat /etc/redhat-release | grep -oP "[0-9]+" | head -1 )

			
echo "************************************************************"
echo " Welcome to Softaculous Virtualizor Installer for Power DNS"
echo "*************************************************************"

#-------------------------------------------------------------------------------------------------------------------------------------
#----------------------------------------------------   PRIMARY NS INSTALLATION  -----------------------------------------------------
#-------------------------------------------------------------------------------------------------------------------------------------

echo 'Installing PDNS ON Primary Nameserver'
echo "-----------------------------------------------------------"

#Install the Virtulizor repo
############################################################
wget http://mirror.softaculous.com/virtualizor/virtualizor.repo -O /etc/yum.repos.d/virtualizor.repo >> $LOG 2>&1

#Install PowerDNS and MySQL and required packages
#Set the MySQL root password
############################################################
echo "2) Installing PDNS (Latest) and MySQL..."

yum -y install epel-release yum-plugin-priorities >> $LOG 2>&1
curl -o /etc/yum.repos.d/powerdns-auth-master.repo https://repo.powerdns.com/repo-files/centos-auth-master.repo >> $LOG 2>&1
yum -y --skip-broken install pdns pdns-backend-mysql sshpass >> $LOG 2>&1

if [ $version = 6 ]; then
	yum -y --skip-broken install mysql mysql-server >> $LOG 2>&1
	chkconfig --levels 235 mysqld on
	chkconfig --levels 235 pdns on
	service mysqld start >> $LOG 2>&1
elif [ $version = 7 ];  then
	yum -y --skip-broken install mariadb-server mariadb >> $LOG 2>&1
	systemctl start mariadb.service >> $LOG 2>&1
	systemctl enable mariadb.service >> $LOG 2>&1
fi

#Set the mysql root password
mysqladmin -u $user password $pass

#Download the PowerDNS SQL schema and import it
############################################################
echo "3) Downloading and importing PDNS Database schema..."
wget http://files.virtualizor.com/pdns.sql >> $LOG 2>&1
mysql --user=$user --password=$pass < pdns.sql


##Configure Power DNS
#Edit /etc/pdns/pdns.conf with your database details:
############################################################
echo "4) Configuring PDNS..."

sed -i 's/^launch=$//g' /etc/pdns/pdns.conf

conf='/# launch=/a\
launch=gmysql\
gmysql-host=localhost\
gmysql-user='$user'\
gmysql-password='$pass'\
gmysql-dbname=powerdns'

sed -i "$conf" /etc/pdns/pdns.conf

#Give permission for the MySQL user to connect from the Virtualizor master server
###################################################################
echo "5) Setting permissions..."
mysql --user $user --password=$pass << eof
GRANT ALL ON powerdns.* TO '$user'@'$master' IDENTIFIED BY '$pass';
eof


#Start the PDNS Daemon
###################################################################
echo "6) Starting the PDNS daemon..."

if [ $version = 6 ]; then
	service mysqld restart >> $LOG 2>&1
	/etc/init.d/pdns start >> $LOG 2>&1
elif [ $version = 7 ];  then
	systemctl restart mariadb.service >> $LOG 2>&1
	systemctl start pdns.service >> $LOG 2>&1
	systemctl enable pdns.service >> $LOG 2>&1	
fi

# Configure MySQL Database Replication
#------------------------------------------------------------------------------------------------------------------------

echo "7) Configuring database replication..."

if [ $version = 6 ]; then
	pos="user=mysql"
elif [ $version = 7 ];  then
	pos="socket="
fi

conf='/'$pos'/a\
server-id=1\
log-bin=mysql-bin\
log-bin-index=mysql-bin.index\
expire-logs-days=10\
max-binlog-size=100M\
binlog-do-db=powerdns'

sed -i "$conf" /etc/my.cnf

#Restart mysql
if [ $version = 6 ]; then
	service mysqld restart >> $LOG 2>&1
elif [ $version = 7 ];  then
	systemctl restart mariadb.service >> $LOG 2>&1	
fi

#Create a new sql user on the master
mysql --user $user --password=$pass << eof
create user pdnsslave;
create user 'pdnsslave'@'*';
grant replication slave on *.* to pdnsslave identified by '$pass';
flush privileges;
eof

#Extract the value of the Mysql master position
echo 'show master status \G' | mysql --user $user --password=$pass  > /tmp/temp.txt
temp=$(cat /tmp/temp.txt | grep Position:)
value=${temp:18}
rm /tmp/temp.txt

#-------------------------------------------------------------------------------------------------------------------------------------
#----------------------------------------------------   SECONDARY NS INSTALLATION  ---------------------------------------------------
#-------------------------------------------------------------------------------------------------------------------------------------

echo 'Installing PDNS ON Secondary Nameserver'
echo "-----------------------------------------------------------"

#Install the Virtulizor repo
##########################################################################
sshpass -p $slavepass ssh -o StrictHostKeyChecking=no root@$slaveip "wget http://mirror.softaculous.com/virtualizor/virtualizor.repo -O /etc/yum.repos.d/virtualizor.repo" >> $LOG 2>&1

#Install PowerDNS and MySQL and required packages
#Set the MySQL root password
############################################################
echo "9) Installing PDNS (Latest) and MySQL..."

sshpass -p $slavepass ssh root@$slaveip "yum -y install epel-release yum-plugin-priorities" >> $LOG 2>&1
sshpass -p $slavepass ssh root@$slaveip "curl -o /etc/yum.repos.d/powerdns-auth-master.repo https://repo.powerdns.com/repo-files/centos-auth-master.repo" >> $LOG 2>&1
sshpass -p $slavepass ssh root@$slaveip "yum -y --skip-broken install pdns pdns-backend-mysql" >> $LOG 2>&1


if [ $version = 6 ]; then
	sshpass -p $slavepass ssh root@$slaveip "yum -y --skip-broken install mysql mysql-server" >> $LOG 2>&1
	sshpass -p $slavepass ssh root@$slaveip "chkconfig --levels 235 mysqld on" >> $LOG 2>&1	
	sshpass -p $slavepass ssh root@$slaveip "chkconfig --levels 235 pdns on" >> $LOG 2>&1	
	sshpass -p $slavepass ssh root@$slaveip "service mysqld start" >> $LOG 2>&1
elif [ $version = 7 ];  then
	sshpass -p $slavepass ssh root@$slaveip "yum -y --skip-broken install mariadb mariadb-server" >> $LOG 2>&1
	sshpass -p $slavepass ssh root@$slaveip "systemctl start mariadb.service" >> $LOG 2>&1	
	sshpass -p $slavepass ssh root@$slaveip "systemctl enable mariadb.service" >> $LOG 2>&1	
	sshpass -p $slavepass ssh root@$slaveip "systemctl enable pdns.service" >> $LOG 2>&1	
fi

#Set the mysql root password
sshpass -p $slavepass ssh root@$slaveip "mysqladmin -u "$user" password $pass"


#Download the PowerDNS SQL schema and import it
############################################################
echo "10) Downloading and importing PDNS Database schema..."
sshpass -p $slavepass ssh root@$slaveip "wget http://files.virtualizor.com/pdns.sql" >> $LOG 2>&1
sshpass -p $slavepass ssh root@$slaveip  mysql --user=$user --password=$pass < pdns.sql


##Configure Power DNS
#Edit /etc/pdns/pdns.conf with your database details:
############################################################
echo "11) Configuring PDNS..."

sshpass -p $slavepass ssh root@$slaveip "sed -i 's/^launch=$//g' /etc/pdns/pdns.conf"

conf='/# launch=/a\
launch=gmysql\
gmysql-host=localhost\
gmysql-user='$user'\
gmysql-password='$pass'\
gmysql-dbname=powerdns'

sshpass -p $slavepass ssh root@$slaveip "sed -i '$conf' /etc/pdns/pdns.conf"

#Give permission for the MySQL user to connect from the Virtualizor master server
###################################################################
#NO NEED FOR THIS STEP AS VIRTUALIZOR DOESNT NEED TO ACESS THE SECONDARY NAMESERVER ONLY THE PRIMARY


#Start the PDNS Daemon
###################################################################
echo "12) Starting the PDNS daemon..."

if [ $version = 6 ]; then
	sshpass -p $slavepass ssh root@$slaveip "service mysqld restart" >> $LOG 2>&1
	sshpass -p $slavepass ssh root@$slaveip  "/etc/init.d/pdns start" >> $LOG 2>&1
elif [ $version = 7 ];  then
	sshpass -p $slavepass ssh root@$slaveip "systemctl restart mariadb.service" >> $LOG 2>&1
	sshpass -p $slavepass ssh root@$slaveip "systemctl start pdns.service" >> $LOG 2>&1	
fi

# Configure MySQL Database Replication on the DNS Slave
#------------------------------------------------------------------------------------------------------------------------

echo "13) Configuring database replication..."

if [ $version = 6 ]; then
	pos="user=mysql"
	retry="master-connect-retry=60"
elif [ $version = 7 ];  then
	pos="socket="
	retry=""
fi

conf='/'$pos'/a\
server-id=2\
'$retry'\
relay-log=slave-relay-bin\
relay-log-index=slave-relay-bin.index\
replicate-do-db=powerdns'

#Edit the PDNS config file
sshpass -p $slavepass ssh root@$slaveip "sed -i '$conf' /etc/my.cnf"

#Restart MySQL
if [ $version = 6 ]; then
	sshpass -p $slavepass ssh root@$slaveip "service mysqld restart" >> $LOG 2>&1
elif [ $version = 7 ];  then
	sshpass -p $slavepass ssh root@$slaveip "systemctl restart mariadb.service" >> $LOG 2>&1	
fi

#Create a new sql user on the master
sshpass -p $slavepass ssh root@$slaveip "mysql --user $user --password=$pass << eof
	change master to
		master_host='$primarynsip',
		master_user='pdnsslave',
		master_password='$pass',
		master_log_file='mysql-bin.000001',
		master_log_pos=$value;
	start slave;
eof"

#END-OF-SCRIPT