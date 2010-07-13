What is it?
===========

A tool that will take machines running mcollective and a small
provisioning agent and bootstrap them through the process of
running puppet.

This is still young code and a work in progress.

Logic Flow
----------

Each node more or less go through the following steps given the
config file:

    --- 
    master: 
      criteria: 
      - ec2_placement_region
      - country
      filter: ""
      agent: puppetca
    target: 
      filter: ""
      agent: provision
    notify:
      filter: "/monitor1/"
      targets:
      - boxcar://rip@devco.net
      - gcal://newservers

 1. Discover all nodes running the 'provision' agent
 1. Pick the first discovered node and start provisioning
 1. Find a list of all masters running 'puppetca' agent
 1. Pick a master based on facts ec2_placement_region and then the country facts. If nothing match, take the first
 1. Calls the 'set_puppet_host' actions giving it the ip of the chosen master
 1. Cleans the certificate from all masters matching the identity of the machine being provisioned
 1. Gets the node to request a new certificate using the 'request_certificate' action
 1. Signs the certificate on all masters
 1. Does an initial puppet run with the 'bootstrap_puppet' action
 1. Does a 2nd puppet run via 'run_puppet' action.  This should remove the provision agent from the node
 1. Notifies my iPhone via boxcar
 1. Adds a calendar entry to my Google Calendar noting the time when the node was provisioned

To do this we re-use a lot of existing agents:

 1. Your masters all need the puppetca agent
 1. Your nodes being provisioned need the provision agent, see agents subdir
 1. You need to have nagger deployed and the node should run the nagger agent
 1. You need some nagger plugins the boxcar and gcal ones are opensource

 Customizing
 -----------

 The basic flow is probably generic enough for most bootstrapping scenarios, cloud or non cloud, the specifics
 of the process should be captured in your agent.  There's a sample agent in the agent subdir

