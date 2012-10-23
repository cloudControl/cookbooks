Chef recipe to install and configure serverdensity
===========


Recipes
=======

default
-------
 - Adds the serverdensity apt repository
 - Installs the sd-agent
 - Registers the host with serverdensity
 - Add alerts to this host
 - Creates the sd-agent config

Requirements
============
 - Developer account for the api key (http://developer.serverdensity.com/)
 - serverdensity account with api access (http://www.serverdensity.com/)
 - apt cookbook

Usage
=====
An attribute 'env' and an encrypted databag 'serverdensity' is needed. The data bag must have entries according to the env attribute and as content:
 - api_key from the developer account
 - username, password, sd_url from the serverdensity account
