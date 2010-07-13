#!/usr/bin/ruby

require 'mcprovision'
require 'pp'

runner = MCProvision::Runner.new("etc/provisioner.yaml")
runner.run
