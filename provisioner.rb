#!/usr/bin/ruby

require 'mcprovision'
require 'pp'

if ARGV.size > 0
    configfile = ARGV[0]
else
    configfile = "/etc/mcollective/provisioner.yaml"
end

runner = MCProvision::Runner.new(configfile)

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
