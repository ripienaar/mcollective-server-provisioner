module MCollective
    module Agent
        class Provision<RPC::Agent
            metadata :name => "Server Provisioning Agent",
                     :description => "Agent to assist in provisioning new servers",
                     :author => "R.I.Pienaar",
                     :license => "Apache 2.0",
                     :version => "1.1",
                     :url => "http://mcollective-plugins.googlecode.com/",
                     :timeout => 360


            # basic server inventory
            action "inventory" do
                ::Facter.reset

                reply[:facts] = PluginManager["facts_plugin"].get_facts
                reply[:classes] = []

                cfile = Config.instance.classesfile
                if File.exist?(cfile)
                    reply[:classes] = File.readlines(cfile).map {|i| i.chomp}
                end
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
        end
    end
end
