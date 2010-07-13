module MCProvision
    class Config
        attr_reader :settings

        def initialize(configfile = "/etc/mcollective/provisioner.yaml")
            Util.log("Loading config from #{configfile}")
            @settings = YAML.load_file(configfile)
        end
    end
end
