module MCProvision
    class Runner
        def initialize(configfile)
            @config = MCProvision::Config.new(configfile)
            @master = MCProvision::PuppetMaster.new(@config)
            @notifier = Notifier.new(@config)
        end

        def run
            Util.log("Starting runner")

            loop do
                Util.log("Looking for machines to provision")
                provisionable = Nodes.new(@config.settings["target"]["agent"], @config.settings["target"]["filter"], @config)

                provisionable.nodes.each do |server|
                    begin
                        provision(server)
                    rescue Exception => e
                        Util.log("Could not provision node #{server.hostname}: #{e.class}: #{e}")
                    end
                end

                sleep 5
            end
        end

        def provision(node)
            node_inventory = node.inventory
            Util.log("Provisioning #{node.hostname} / #{node_inventory[:facts]['ipaddress_eth0']}")

            chosen_master, master_inventory = pick_master_from(@config.settings["master"]["criteria"], node_inventory[:facts])

            master_ip = master_inventory[:facts]['ipaddress']

            Util.log("Provisioning node against #{chosen_master.hostname} / #{master_ip}")

            # calls set_puppet_host
            node.set_puppet_host(master_ip)

            # calls clean on all puppetmasters
            @master.clean_cert(node.hostname)

            # Gets the node to request a CSR
            node.send_csr

            # Sign it
            @master.sign(node.hostname)

            # Bootstrap it
            node.bootstrap

            @notifier.notify("Provisioned #{node.hostname} against #{chosen_master.hostname}", "New Node")
        end

        private
        # Take an array of facts and the node facts.
        # Discovers all masters and go through their inventories
        # till we find a match, else return the first one.
        def pick_master_from(facts, node)
            masters = @master.find_all
            chosen_master = masters.first

            master_inventories = {}

            # build up a list of the master inventories
            masters.each do |master|
                master_inventories[master.hostname] = master.inventory
            end

            # For every configured fact
            facts.each do |fact|
                # Check if the node has it
                if node.include?(fact)
                    # Now check every master
                    masters.each do |master|
                        master_facts = master_inventories[master.hostname][:facts]
                        if master_facts.include?(fact)
                            # if they match, we have a winner
                            if master_facts[fact] == node[fact]
                                Util.log("Picking #{master.hostname} for puppetmaster based on #{fact} == #{node[fact]}")
                                chosen_master = master
                            end
                        end
                    end
                end
            end

            raise "Could not find any masters" if chosen_master.nil?

            return [chosen_master, master_inventories[chosen_master.hostname]]
        end
    end
end
