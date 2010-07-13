module MCProvision
    class PuppetMaster
        def initialize(config)
            @config = config

            setup
        end

        # Find all nodes with the configured master agent
        def find_all
            masters = Nodes.new(@config.settings["master"]["agent"], @config.settings["master"]["filter"], @config)

            masters.nodes
        end

        # Cleans a cert from all masters
        def clean_cert(certname)
            Util.log("Clean certificate #{certname} from all masters")
            @puppetca.clean(:certname => certname)
        end

        # Signs a cert on all masters
        def sign(certname)
            Util.log("Signing certificate #{certname} on all masters")

            @puppetca.list.each do |list|
                if list[:data][:requests].include?(certname)
                    @puppetca.sign(:certname => certname)

                    return
                end
            end

            raise "Could not find certificate #{certname} to sign on any master"
        end

        # resets the rpc client
        def reset
            @puppetca.reset
        end

        private
        def setup
            agent = @config.settings["master"]["agent"]
            @puppetca = rpcclient(agent)
            @puppetca.progress = false
            @puppetca.filter = MCProvision::Util.parse_filter(agent, @config.settings["master"]["filter"])
        end
    end
end
