#!/usr/bin/ruby

require 'mcprovision'
require 'pp'

runner = MCProvision::Runner.new("etc/provisioner.yaml")

begin
    if runner.config.settings["daemonize"] || false
        MCProvision::Util.daemonize do
            runner.run
        end
    else
        runner.run
    end
rescue Exception => e
    MCProvision.info("Runner failed unexpectedly: #{e.class}: #{e}")
    sleep 5
    retry
end
