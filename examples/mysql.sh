#!/bin/sh

# Define variables to use in the template
export MYSQL_CONFIG_DIR=/etc/mysql 
export MYSQL_DATA_DIR=/var/lib/mysql
export MYSQL_LOG_DIR=/var/log
export MYSQL_USER=mysql

# Use templater to generate mysql.cnf
../templater.sh mysql.cnf.tpl > mysql.cnf
