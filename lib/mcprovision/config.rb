module MCProvision
    class Config
        attr_reader :settings

        def initialize(configfile = "/etc/mcollective/provisioner.yaml")
            Util.log("Loading config from #{configfile}")
            @settings = YAML.load_file(configfile)

            if @settings.include?("logfile") && @settings.include?("loglevel")
                MCProvision.logfile(@settings["logfile"], @settings["loglevel"])
            else
                MCProvision.logfile("/dev/stderr", "debug")
            end
        end
    end
end
