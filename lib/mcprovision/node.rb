module MCProvision
    class Node
        attr_reader :hostname

        def initialize(hostname, config, agent)
            @config = config
            @hostname = hostname
            @agent = agent

            setup
        end

        # Gets the inventory from the discovery agent on the node
        def inventory
            result = {}

            @node.client.req("inventory", "discovery", @node.client.options, 1) do |resp|
                result[:agents] = resp[:body][:agents]
                result[:facts] = resp[:body][:facts]
                result[:classes] = resp[:body][:classes]
            end

            result
        end

        # sets the ip of the puppet master host using the
        # set_puppet_host action on the node
        def set_puppet_host(ipaddress)
            MCProvision.info("Calling set_puppet_host with ip #{ipaddress}")
            @node.custom_request("set_puppet_host", {:ipaddress => ipaddress}, @hostname, {"identity" => @hostname})
        end

        # calls the request_certificate action on the node being provisioned
        def send_csr
            MCProvision.info("Calling request_certificate")
            @node.custom_request("request_certificate", {}, @hostname, {"identity" => @hostname})
        end

        # calls the bootstrap_puppet action to do initial puppet run
        def bootstrap
            MCProvision.info("Calling bootstrap_puppet")
            result = @node.custom_request("bootstrap_puppet", {}, @hostname, {"identity" => @hostname})

            check_puppet_output(result.first[:data][:output].split("\n"))
        end

        # Do the final run of the client by calling run_puppet
        def run_puppet
            MCProvision.info("Calling run_puppet")
            result = @node.custom_request("run_puppet", {}, @hostname, {"identity" => @hostname})

            check_puppet_output(result.first[:data][:output].split("\n"))
        end

        private
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

        def setup
            @node = rpcclient(@agent)
            @node.identity_filter @hostname
            @node.progress = false
        end
    end
end
