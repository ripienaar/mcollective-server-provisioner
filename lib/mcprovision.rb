require 'mcollective'
require 'yaml'

include MCollective::RPC

module MCProvision
    autoload :Config, "mcprovision/config"
    autoload :PuppetMaster, "mcprovision/puppetmaster"
    autoload :Nodes, "mcprovision/nodes"
    autoload :Node, "mcprovision/node"
    autoload :Util, "mcprovision/util"
    autoload :Runner, "mcprovision/runner"
    autoload :Notifier, "mcprovision/notifier"
end
