module MCProvision
    class Runner
        attr_reader :config

        def initialize(configfile)
            @config = MCProvision::Config.new(configfile)
            @master = MCProvision::PuppetMaster.new(@config)
            @notifier = Notifier.new(@config)

            Signal.trap("INT") do
                MCProvision.info("Received INT signal, exiting.")
                exit!
            end
        end

        def run
            begin
                MCProvision.info("Starting runner")

                loop do
                    MCProvision.info("Looking for machines to provision")
                    provisionable = Nodes.new(@config.settings["target"]["agent"], @config.settings["target"]["filter"], @config)

                    provisionable.nodes.each do |server|
                        begin
                            provision(server)
                        rescue Exception => e
                            MCProvision.warn("Could not provision node #{server.hostname}: #{e.class}: #{e}")
                            MCProvision.warn(e.backtrace.join("\n\t")) if @config.settings["loglevel"] == "debug"
                        end
                    end

                    sleep 5
                end
            rescue SignalException => e
            rescue Exception => e
                MCProvision.warn("Runner failed: #{e.class}: #{e}")
                MCProvision.warn(e.backtrace.join("\n\t")) if @config.settings["loglevel"] == "debug"
                sleep 2
                retry
            end
        end

        # Main provisioner body, does the following:
        #
        # - Find the node ip address based on target/ipaddress_fact
        # - Checks if the node is locked for provisioning
        # - Creates a lock file on the node so no other provisioner threads will interfere with it
        # - picks a puppet master based on configured criteria
        # - determines the ip address of the picked master
        # - calls to the set_puppet_hostname action which typically adds 'puppet' to /etc/hosts
        # - checks if the node already has a cert
        #   - if it doesnt
        #     - clean the cert from all puppetmasters
        #     - instructs the client to do a run which would request the cert
        #     - signs it on the chosen master
        # - call puppet_bootstrap_stage which could run a small bootstrap environment client
        # - call puppet_final_run which would do a normal puppet run, this steps block till completed
        # - sends a notification to administrators
        def provision(node)
            node_inventory = node.inventory
            node_ipaddress_fact = @config.settings["target"]["ipaddress_fact"] || "ipaddress"
            master_ipaddress_fact = @config.settings["master"]["ipaddress_fact"] || "ipaddress"

            raise "Could not determine node ip address from fact #{node_ipaddress_fact}" unless node_inventory[:facts].include?(node_ipaddress_fact)
            raise "Node already being provisioned" if node.locked?

            steps = @config.settings["steps"].keys.select{|s| @config.settings["steps"][s] }
            MCProvision.info("Provisioning #{node.hostname} / #{node_inventory[:facts][node_ipaddress_fact]} with steps #{steps.join ' '}")

            chosen_master, master_inventory = pick_master_from(@config.settings["master"]["criteria"], node_inventory[:facts])

            raise "Could not determine master ip address from fact #{master_ipaddress_fact}" unless master_inventory[:facts].include?(master_ipaddress_fact)
            master_ip = master_inventory[:facts][master_ipaddress_fact]

            MCProvision.info("Provisioning node against #{chosen_master.hostname} / #{master_ip}")

            # calls set_puppet_host
            node.set_puppet_host(master_ip) if @config.settings["steps"]["set_puppet_hostname"]

            # Only do certificate management if the node is clean and doesnt already have a cert
            unless node.has_cert?
                # calls clean on all puppetmasters
                @master.clean_cert(node.hostname) if @config.settings["steps"]["clean_node_certname"]

                # Gets the node to request a CSR
                node.send_csr if @config.settings["steps"]["send_node_csr"]

                # Sign it
                @master.sign(node.hostname) if @config.settings["steps"]["sign_node_csr"]
            else
                MCProvision.info("Skipping SSL certificate management for node - already has a cert")
            end

            # Bootstrap it
            node.bootstrap if @config.settings["steps"]["puppet_bootstrap_stage"]

            # Do final run
            node.run_puppet if @config.settings["steps"]["puppet_final_run"]

            @notifier.notify("Provisioned #{node.hostname} against #{chosen_master.hostname}", "New Node") if @config.settings["steps"]["notify"]
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
                                MCProvision.info("Picking #{master.hostname} for puppetmaster based on #{fact} == #{node[fact]}")
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
