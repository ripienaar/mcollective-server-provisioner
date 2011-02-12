require 'mcollective'
require 'yaml'
require 'logger'
require 'pp'

include MCollective::RPC

module MCProvision
    autoload :Config, "mcprovision/config"
    autoload :PuppetMaster, "mcprovision/puppetmaster"
    autoload :Nodes, "mcprovision/nodes"
    autoload :Node, "mcprovision/node"
    autoload :Util, "mcprovision/util"
    autoload :Runner, "mcprovision/runner"
    autoload :Notifier, "mcprovision/notifier"

    VERSION = "1.0.0"

    def self.logfile(logfile, loglevel)
        @@logfile = logfile
        @@logger = Logger.new(logfile, 5, 102400)

        case loglevel
            when "debug"
                @@logger.level = Logger::DEBUG
            when "warn"
                @@logger.level = Logger::WARN
            else
                @@logger.level = Logger::INFO
        end
    end

    def self.version
        VERSION
    end

    def self.warn(msg)
        MCProvision.log(Logger::WARN, msg)
    end

    def self.info(msg)
        MCProvision.log(Logger::INFO, msg)
    end

    def self.debug(msg)
        MCProvision.log(Logger::DEBUG, msg)
    end

    def self.log(severity, msg)
        begin
            from = File.basename(caller[1])
            @@logger.add(severity) { "#{$$} #{from}: #{msg}" }
        rescue Exception => e
        end
    end
end
