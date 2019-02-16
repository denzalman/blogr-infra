#!/bin/bash
wget https://repo.percona.com/apt/percona-release_latest.$(lsb_release -sc)_all.deb
sudo dpkg -i percona-release_latest.$(lsb_release -sc)_all.deb
sudo percona-release setup ps80

ROOTPASSWDDB="$(openssl rand -base64 12)"
echo "rootdbpass: $ROOTPASSWDDB" >> dbpass.txt

#DONE: CHANGE ROOT PASSWORD! 
package="percona-server-server-5.7"
c1="$package percona-server-server-5.7/root-pass password"
sudo debconf-set-selections <<< "$c1 $ROOTPASSWDDB"
c2="$package percona-server-server-5.7/re-root-pass password"
sudo debconf-set-selections <<< "$c2 $ROOTPASSWDDB"

sudo apt-get install -qq -y percona-server-server-5.7 percona-server-client-5.7

#TODO: Make initial creation if not exist DATABASE <BLOGR> and tables <users> and <messages>:

# CREATE DATABASE blogr;
mysql -uroot -p${ROOTPASSWDDB} -e "CREATE DATABASE blogr /*\!40100 DEFAULT CHARACTER SET utf8 */;"
#mysql -uroot -p${ROOTPASSWDDB} -e "USE blogr;"
#mysql -uroot -p${ROOTPASSWDDB} -e "CREATE TABLE user (id INT NOT NULL AUTO_INCREMENT, name VARCHAR(20) NOT NULL, password VARCHAR(20) NOT NULL, PRIMARY KEY (id)) ENGINE=INNODB;"
mysql -uroot -p${ROOTPASSWDDB} -e "GRANT ALL PRIVILEGES ON blogr.* TO 'blogr'@'%' IDENTIFIED BY 'blogr';"