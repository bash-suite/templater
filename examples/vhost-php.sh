#!/bin/sh

# Define variables to use in the template
export USER=me 
export DOMAIN=mydomain.com

# Use templater to generate vhostvhost-php.conf
../templater.sh vhost-php.conf.tpl > vhost-php.conf
