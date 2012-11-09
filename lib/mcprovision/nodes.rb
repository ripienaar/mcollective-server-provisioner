module MCProvision
  class Nodes
    attr_reader :nodes, :filter, :agent

    def initialize(agent, filter, config)
      @filter = filter
      @agent = agent
      @config = config

      setup
      find_all
    end

    private
    def find_all
      @nodes = @rpc.discover.map do |node|
        Node.new(node, @config, @agent)
      end
    end

    def setup
      @rpc = rpcclient(@agent)
      @rpc.filter = Util.parse_filter(@agent, @filter)
      @rpc.progress = false
    end
  end
end
