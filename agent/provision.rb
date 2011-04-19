module MCollective
    module Agent
        class Provision<RPC::Agent
            metadata :name => "Server Provisioning Agent",
                     :description => "Agent to assist in provisioning new servers",
                     :author => "R.I.Pienaar",
                     :license => "Apache 2.0",
                     :version => "2.0",
                     :url => "http://www.devco.net/",
                     :timeout => 60


            def startup_hook
                config = Config.instance

                certname = PluginManager["facts_plugin"].get_fact("hostname").downcase
                certname = config.identity unless certname

                @puppetcert = config.pluginconf["provision.certfile"] || "/var/lib/puppet/ssl/certs/#{certname}.pem"
                @lockfile = config.pluginconf["provision.lockfile"] || "/tmp/mcollective_provisioner_lock"
                @puppetd = config.pluginconf["provision.puppetd"] || "/usr/sbin/puppetd"
                @fact_add = config.pluginconf["provision.fact_add"] || "/usr/bin/fact-add"
            end

            action "set_puppet_host" do
                validate :ipaddress, :ipv4address

                begin
                    hosts = File.readlines("/etc/hosts")

                    File.open("/etc/hosts", "w") do |hosts_file|
                        hosts.each do |host|
                            hosts_file.puts host unless host =~ /puppet/
                        end

                        hosts_file.puts "#{request[:ipaddress]}\tpuppet"
                    end
                rescue Exception => e
                    fail "Could not add hosts entry: #{e}"
                end
            end

            # Adds a new fact
            action "fact_mod" do
                validate :fact, :value

                reply[:exitcode] = run("#{@fact_add} #{request[:fact]} #{request[:value]}", :stdout => :output, :stderr => :err, :chomp => true)

                if reply[:exitcode] != 0
                    File.unlink(@lockfile)
                    fail "Fact returned #{reply[:exitcode]}"
                end
            end

            # does a run of puppet with --tags no_such_tag_here
            action "request_certificate" do
                reply[:exitcode] = run("#{@puppetd} --test --tags no_such_tag_here --color=none --summarize", :stdout => :output, :stderr => :err, :chomp => true)
                reply[:exitcode] = 0

                # dont fail here if exitcode isnt 0, it'll always be non zero
            end

            # does a run of puppet with --environment bootstrap or similar
            action "bootstrap_puppet" do
                reply[:exitcode] = run("#{@puppetd} --test --environment bootstrap --color=none --summarize", :stdout => :output, :stderr => :err, :chomp => true)

                if reply[:exitcode] == 1
                    File.unlink(@lockfile)
                    fail "Puppet returned #{reply[:exitcode]}"
                end
            end

            # does a normal puppet run
            action "run_puppet" do
                reply[:exitcode] = run("#{@puppetd} --test --color=none --summarize", :stdout => :output, :stderr => :err, :chomp => true)
                reply[:exitcode] = 0
            end

            # start puppet
            action "start_puppet" do
                reply[:exitcode] = run("service puppet start", :stdout => :output, :stderr => :err, :chomp => true)

                if reply[:exitcode] != 0
                    File.unlink(@lockfile)
                    fail "Puppet returned #{reply[:exitcode]}"
                end
            end

            # cycle_puppet_run
            action "cycle_puppet_run" do
                reply[:exitcode] = run("#{@puppetd} --test --color=none --summarize; #{@puppetd} --test --color=none --summarize; #{@puppetd} --test --color=none --summarize", :stdout => :output, :stderr => :err, :chomp => true)
                reply[:exitcode] = 0
                # Even if this errors (it will), we don't care
            end
 
            # stop puppet
            action "stop_puppet" do
                reply[:exitcode] = run("service puppet stop", :stdout => :output, :stderr => :err, :chomp => true)

                if reply[:exitcode] != 0
                    File.unlink(@lockfile)
                    fail "Puppet returned #{reply[:exitcode]}"
                end
            end

            # clean client cert
            action "clean_cert" do
                reply[:exitcode] = run("find /var/lib/puppet/ssl -type f -exec rm {} \+ ", :stdout => :output, :stderr => :err, :chomp => true)

                if reply[:exitcode] != 0
                    File.unlink(@lockfile)
                    fail "find returned #{reply[:exitcode]}"
                end
            end

            action "has_cert" do
                reply[:has_cert] = has_cert?
            end

            action "provisioned" do
                isprovisioned = PluginManager["facts_plugin"].get_fact("provision-status")
                if isprovisioned == "provisioned"
                    reply[:provisioned] = true
                else
                    reply[:provisioned] = false
                end 
            end

            action "lock_deploy" do
                reply.fail! "Already locked" if locked?

                File.open(@lockfile, "w") {|f| f.puts Time.now}

                reply[:lockfile] = @lockfile

                reply.fail! "Failed to lock the install" unless locked?
            end

            action "is_locked" do
                reply[:locked] = locked?
            end

            action "unlock_deploy" do
                File.unlink(@lockfile)
                reply[:unlocked] = locked?
                reply.fail! "Failed to unlock the install" if locked?
            end

            private
            def has_cert?
                File.exist?(@puppetcert)
            end

            def locked?
                File.exist?(@lockfile)
            end

        end
    end
end
