What is it?
===========

A tool that will take machines running mcollective and a small
provisioning agent and bootstrap them through the process of
running puppet.

Logic Flow
----------

Each node more or less go through the following steps given the config file:

	---
	logfile: /var/log/mcprovision.log
	loglevel: debug
	daemonize: true
	sleeptime: 10
	steps:
	  lock: true
	  set_puppet_hostname: true
	  clean_node_certname: true
	  send_node_csr: true
	  sign_node_csr: true
	  puppet_bootstrap_stage: true
	  puppet_final_run: true
	  unlock: true
	  notify: true
	master:
	  criteria:
	  - ec2_placement_region
	  - country
	  filter: ""
	  agent: puppetca
	  ipaddress_fact: ipaddress
	target:
	  filter: ""
	  agent: provision
	  ipaddress_fact: ipaddress
	notify:
	  filter: ""
	  agent: angelianotify
	  targets:
	  - boxcar://you@example.com

 1. Discover all nodes running the 'provision' agent
 1. Pick the first discovered node and start provisioning
 1. Find a list of all masters running 'puppetca' agent
 1. Pick a master based on facts ec2_placement_region and then the country facts. If nothing match, take the first
 1. Attempts to create a lock on the node to prevent other threads or provisioners from finding this node
 1. Check if the node already has a cert and skips certificate steps if it does
  1. Calls the 'set_puppet_host' actions giving it the ip of the chosen master
  1. Cleans the certificate from all masters matching the identity of the machine being provisioned
  1. Gets the node to request a new certificate using the 'request_certificate' action
  1. Signs the certificate on all masters
 1. Does an initial puppet run with the 'bootstrap_puppet' action
 1. Does a 2nd puppet run via 'run_puppet' action.  This should remove the provision agent from the node
 1. Removes the lock file on the node
 1. Notifies my iPhone via boxcar

To do this we re-use a lot of existing agents:

 1. Your masters all need the puppetca agent
 1. Your nodes being provisioned need the provision agent, see agents subdir
 1. You need to have angelia deployed and the node should run the angelia agent
 1. You need some angelia plugins the boxcar and gcal ones are opensource

Customizing
-----------

The basic flow is probably generic enough for most bootstrapping scenarios, cloud or non cloud, the specifics
of the process should be captured in your agent.  There's a sample agent in the agent subdir.

You can enable and disable individual steps that doesn't fit your needs in the steps section of the config file

Changelog
---------

- 2011/02/04 - Improved error handling
- 2011/02/04 - Make the facts used to determine ip address connfigurable
- 2011/02/04 - Log backtraces when run in debug mode
- 2011/02/04 - Make the agent names for all the components configurable
- 2011/02/06 - Check if a machine already has a cert and skip cert related steps if it does
- 2011/02/06 - Optimise performance of obtaining the node inventory
- 2011/02/06 - Add lock and unlock stepts
- 2011/02/06 - Make the node code more DRY
- 2011/02/06 - When notifying communicate with only 1 of the discovered nodes providing a notification service


License
-------

Apache 2.0

Contact
-------

Contact R.I.Pienaar <rip@devco.net> / @ripienaar / www.devco.net with questions
