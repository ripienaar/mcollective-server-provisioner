module MCProvision::Util
    # Parses a -W style filter and return a std filter option
    def self.parse_filter(agent, filter)
        result = MCollective::Util.empty_filter

        filter.split(" ").each do |f|
            if f =~ /^(.+?)=(.+)/
                result["fact"] << {:fact => $1, :value => $2}
            else
                result["cf_class"] << f
            end
        end

        result["agent"] << agent

        result
    end

    # Daemonize the current process
    def self.daemonize
        fork do
            Process.setsid
            exit if fork
            Dir.chdir('/tmp')
            STDIN.reopen('/dev/null')
            STDOUT.reopen('/dev/null', 'a')
            STDERR.reopen('/dev/null', 'a')

            yield
        end
    end

    def self.log(msg)
        MCProvision.debug(msg)
    end
end
