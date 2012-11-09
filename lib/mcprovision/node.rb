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

    # Do the final run of the client by calling run_puppet
    def run_puppet
      MCProvision.info("Calling run_puppet")
      result = request("run_puppet")
      check_puppet_output(result[:data][:output].split("\n"))
    end

    private
    # Wrapper that calls to a node, checks the result structure and status messages and return
    # the result structure for the node
    def request(action, arguments={})
      result = @node.custom_request(action, arguments, @hostname, {"identity" => @hostname})

      raise "Uknown result from remote node: #{result.pretty_inspect}" unless result.is_a?(Array)

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
      end
    end

    # Gets the inventory from the discovery agent on the node
    def fetch_inventory
      rpcutil = rpcclient("rpcutil")
      rpcutil.identity_filter @hostname
      rpcutil.progress = false

      result = rpcutil.inventory.first

      {:agents => result[:data][:agents], :facts => result[:data][:facts], :classes => result[:data][:classes]}
    end

    def setup
      @node = rpcclient(@agent)
      @node.identity_filter @hostname
      @node.progress = false
    end
  end
end
