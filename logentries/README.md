Chef recipe to install and configure logentries
===========

Recipes
=======

default
-------
 - Adds the logentries apt repository
 - Installs the logentries packages
 - Registers the host with logentries
 - Installs the logentries-daemon package
 - Follows /var/log/syslog, /var/log/chef/client.log and le follow /var/log/cloud-init.log 
 - Restarts the logentries service

Requirements
============
 - Logentries account (https://logentries.com/)
 - Logentries userkey
 - apt cookbook
 - prepared log types (syslog)

Usage
=====
An attribute 'env' and an encrypted databag 'logentries' is needed. The data bag must have entries according to the env attribute and as content a userkey with the logentries user-key.
