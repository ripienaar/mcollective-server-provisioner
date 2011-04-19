module MCProvision
    class Node
        attr_reader :hostname, :inventory

        def initialize(hostname, config, agent)
            @config = config
            @hostname = hostname
            @agent = agent

            setup
            @inventory = fetch_inventory
        end

        def lock
            MCProvision.info("Creating lock file on node")
            request("lock_deploy")
        end

        def unlock
            MCProvision.info("Removing lock file on node")
            request("unlock_deploy")
        end

        # Check if the lock file exist
        def locked?
            MCProvision.info("Checking if the deploy is locked on this node")
            result = request("is_locked")

            result[:data][:locked]
        end

        # Do we already have a puppet cert?
        def has_cert?
            MCProvision.info("Finding out if we already have a certificate")
            result = request("has_cert")

            result[:data][:has_cert]
        end

        # Do we already have a puppet cert?
        def provisioned?
            MCProvision.info("Finding out if we already finished provisioning")
            result = request("provisioned")

            result[:data][:provisioned]
        end

        # sets the ip of the puppet master host using the
        # set_puppet_host action on the node
        def set_puppet_host(ipaddress)
            MCProvision.info("Calling set_puppet_host with ip #{ipaddress}")
            request("set_puppet_host", {:ipaddress => ipaddress})
        end

        # calls the request_certificate action on the node being provisioned
        def send_csr
            MCProvision.info("Calling request_certificate")
            request("request_certificate")
        end

        # calls the bootstrap_puppet action to do initial puppet run
        def bootstrap
            MCProvision.info("Calling bootstrap_puppet")
            result = request("bootstrap_puppet")

            check_puppet_output(result[:data][:output].split("\n"))
        end

        # calls the clean_cert to clean certificate on remote side
        def clean_cert
            MCProvision.info("Calling clean_cert")
            result = request("clean_cert")
        end

        # calls stop_puppet to stop puppet service
        def stop_puppet
            MCProvision.info("Calling stop_puppet")
            result = request("stop_puppet")
        end

        # calls start_puppet to start puppet service
        def start_puppet
            MCProvision.info("Calling start_puppet")
            result = request("start_puppet")
        end

        # Do the final run of the client by calling run_puppet
        def run_puppet
            MCProvision.info("Calling run_puppet")
            result = request("run_puppet")
        end

        # Do cycle puppet run
        def cycle_puppet_run
            MCProvision.info("Calling cycle_puppet_run")
            result = request("cycle_puppet_run")
        end
 
        # Modify or add facts to client
        def fact_mod(fact,value)
            MCProvision.info("Calling fact_add with fact #{fact} and value #{value}")
            result = request("fact_mod", {:fact => fact, :value => value})
        end

        private
        # Wrapper that calls to a node, checks the result structure and status messages and return
        # the result structure for the node
        def request(action, arguments={})
            begin
                result = @node.custom_request(action, arguments, @hostname, {"identity" => @hostname})
            rescue StandardError => e
                action = "unlock_deploy"
                arguments = ""
                @node.custom_request(action, arguments, @hostname, {"identity" => @hostname})
            end

            raise "Uknown result from remote node: #{result.pretty_inspect}" unless result.is_a?(Array)

            #MCProvision.info("debug response: #{result.pretty_inspect}"

            raise "Did not receive a response from #{@hostname} in the allowed time" if result.empty?

            result = result.first

            unless result[:statuscode] == 0
                raise "Request to #{@hostname}##{action} failed: #{result[:statusmsg]}"
            end

            result
        end

        # checks output from puppetd that ran with --summarize for errors
        def check_puppet_output(output)
            output.each do |o|
                if o =~ /^\s+Failed: (\d+)/
                    raise "Puppet failed due to #{$1} failed resource(s)" unless $1 == "0"
                end

                if o =~ /^\s+Skipped: (\d+)/
                    raise "Puppet failed due to #{$1} skipped resource(s)" unless $1 == "0"
                end
            end
        end

        # Gets the inventory from the discovery agent on the node
        def fetch_inventory
            result = {}

            # Does a MC::Client request to the main discovery agent, we should use the
            # rpcutil agent for this
            @node.client.req("inventory", "discovery", @node.client.options, 1) do |resp|
                result[:agents] = resp[:body][:agents]
                result[:facts] = resp[:body][:facts]
                result[:classes] = resp[:body][:classes]
            end

            result
        end

        def setup
            @node = rpcclient(@agent)
            @node.identity_filter @hostname
            @node.progress = false
            #MCProvision.info(@node.options.pretty_inspect)
        end
    end
end
