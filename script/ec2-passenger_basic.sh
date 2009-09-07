#!/bin/bash

# ec2-run-instances --key build --user-data-file ec2-userdata.sh --group default --group basic ami-ed46a784

set -e -x
export DEBIAN_FRONTEND=noninteractive
apt-get update && apt-get upgrade -y

# git
apt-get install -y git-core

# ruby
wget http://rubyforge.org/frs/download.php/58679/ruby-enterprise_1.8.6-20090610_i386.deb
dpkg -i ruby-enterprise_1.8.6-20090610_i386.deb
ln -s /opt/ruby-enterprise/ /opt/ruby
# put ruby-enterprise into the main path
mkdir -p /usr/local/bin
rubybin=/opt/ruby/bin
for file in $( ls $rubybin ) ; do ln -nfs $rubybin/$file /usr/local/bin/$file; done

# apache
apt-get install -y apache2 apache2-prefork-dev libapr1-dev
cd /etc/apache2/mods-enabled
ln -s ../mods-available/rewrite.load
ln -s ../mods-available/headers.load
mkdir -p /mnt/log/apache
chown www-data:www-data /mnt/log/apache
/etc/init.d/apache2 restart

# passenger
/usr/local/bin/passenger-install-apache2-module -a
echo "LoadModule passenger_module /opt/ruby-enterprise/lib/ruby/gems/1.8/gems/passenger-2.2.2/ext/apache2/mod_passenger.so 
PassengerRoot /opt/ruby-enterprise/lib/ruby/gems/1.8/gems/passenger-2.2.2
PassengerRuby /opt/ruby-enterprise/bin/ruby" > /etc/apache2/conf.d/passenger
/etc/init.d/apache2 restart

# mysql
apt-get install -y mysql-server mysql-client libmysqlclient15-dev
/etc/init.d/mysql stop
mkdir -p /mnt/log/mysql
mkdir -p /mnt/mysql_data/tmp
chown -R mysql:mysql /mnt/log/mysql /mnt/mysql_data
cp /etc/mysql/my.cnf /etc/mysql/my.cnf.bak
sed -i "s/datadir\s*=[^\n]*/datadir = \/mnt\/mysql_data/g" /etc/mysql/my.cnf
sed -i 's/tmpdir\s*=[^\n]*/tmpdir = \/mnt\/mysql_data\/tmp/g' /etc/mysql/my.cnf
sed -i 's/log_slow_queries\s*=[^\n]*/log_slow_queries = \/mnt\/log\/mysql\/mysql-slow.log/g' /etc/mysql/my.cnf
sed -i 's/\#log_bin\s*=[^\n]*/log_bin = \/mnt\/log\/mysql\/mysql-bin.log/g' /etc/mysql/my.cnf
/etc/init.d/mysql start

# memcached
apt-get install -y memcached

# gems
/usr/local/bin/gem install --no-rdoc --no-ri mysql
