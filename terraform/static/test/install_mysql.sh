wget https://repo.percona.com/apt/percona-release_latest.$(lsb_release -sc)_all.deb
sudo dpkg -i percona-release_latest.$(lsb_release -sc)_all.deb
sudo percona-release setup ps80

ROOTPASSWDDB="password"

#DONE: CHANGE ROOT PASSWORD! 
package="percona-server-server-5.7"
c1="$package percona-server-server-5.7/root-pass password"
sudo debconf-set-selections <<< "$c1 $ROOTPASSWDDB"
#sudo debconf-set-selections <<< "$c1 rootpassword"
c2="$package percona-server-server-5.7/re-root-pass password"
sudo debconf-set-selections <<< "$c2 $ROOTPASSWDDB"
#sudo debconf-set-selections <<< "$c2 rootpassword"

sudo apt-get update
sudo apt-get install -qq -y percona-server-server-5.7 percona-server-client-5.7
