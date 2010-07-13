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
                @config.settings["notify"]["targets"].each do |recipient|
                    Util.log("Notifying #{recipient} of new node")
                    @rpc.sendmsg(:message => msg, :subject => subject, :recipient => recipient)
                end
            end
        end

        private
        def setup
            @rpc = rpcclient("naggernotify")
            @rpc.progress = false
            @rpc.filter = Util.parse_filter("naggernotify", @config.settings["notify"]["filter"])
        end
    end
end
