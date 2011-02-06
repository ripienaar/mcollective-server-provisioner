module MCollective
    module Agent
        class Provision<RPC::Agent
            metadata :name => "Server Provisioning Agent",
                     :description => "Agent to assist in provisioning new servers",
                     :author => "R.I.Pienaar",
                     :license => "Apache 2.0",
                     :version => "2.0",
                     :url => "http://www.devco.net/",
                     :timeout => 360


            def startup_hook
                config = Config.instance

                certname = PluginManager["facts_plugin"].get_fact("fqdn")
                certname = config.identity unless certname

                @puppetcert = config.pluginconf["provision.certfile"] || "/var/lib/puppet/ssl/certs/#{certname}.pem"
                @lockfile = config.pluginconf["provision.lockfile"] || "/tmp/mcollective_provisioner_lock"
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

            # does a run of puppet with --tags no_such_tag_here
            action "request_certificate" do
                reply[:output] = %x[/usr/sbin/puppetd --test --tags no_such_tag_here --color=none --summarize]
                reply[:exitcode] = $?.exitstatus

                # dont fail here if exitcode isnt 0, it'll always be non zero
            end

            # does a run of puppet with --environment bootstrap or similar
            action "bootstrap_puppet" do
                reply[:output] = %x[/usr/sbin/puppetd --test --environment bootstrap --color=none --summarize]
                reply[:exitcode] = $?.exitstatus

                fail "Puppet returned #{reply[:exitcode]}" if reply[:exitcode] != 0
            end

            # does a normal puppet run
            action "run_puppet" do
                reply[:output] = %x[/usr/sbin/puppetd --test --color=none --summarize]
                reply[:exitcode] = $?.exitstatus

                fail "Puppet returned #{reply[:exitcode]}" if reply[:exitcode] != 0
            end

            action "has_cert" do
                reply[:has_cert] = has_cert?
            end

            action "lock_deploy" do
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
