module MCProvision
    class Notifier
        def initialize(config)
            @config = config

            if @config.settings.include?("notify")
                setup
            end
        end

        def notify(msg, subject)
            if @config.settings.include?("notify")
                raise "No notification targets specified" unless @config.settings["notify"].include?("targets")
                raise "No notification targets specified" if @config.settings["notify"]["targets"].empty?

                @config.settings["notify"]["targets"].each do |recipient|
                    MCProvision.info("Notifying #{recipient} of new node")

                    raise "Could not find any instances of the '#{@config.settings['notify']['agent']}' agent" if @rpc.discover.empty?
                    @rpc.sendmsg(:message => msg, :subject => subject, :recipient => recipient)
                end
            end
        end

        private
        def setup
            agent = @config.settings["notify"]["agent"] || "angelianotify"

            @rpc = rpcclient(agent)
            @rpc.progress = false

            # in environments with many notifiers running only speak to 1
            @rpc.limit_targets = 1

            @rpc.filter = Util.parse_filter(agent, @config.settings["notify"]["filter"])
        end
    end
end
