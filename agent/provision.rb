module MCollective
  module Agent
    class Provision<RPC::Agent
      activate_when do
        !File.exist?(Config.instance.pluginconf.fetch("provision.disablefile", "/etc/mcollective/provisioner.disable"))
      end

      def startup_hook
        config = Config.instance

        certname = PluginManager["facts_plugin"].get_fact("fqdn")
        certname = config.identity unless certname

        @puppetcert = config.pluginconf.fetch("provision.certfile", "/var/lib/puppet/ssl/certs/#{certname}.pem")
        @lockfile = config.pluginconf.fetch("provision.lockfile", "/etc/mcollective/provisioner.lock")
        @disablefile = config.pluginconf.fetch("provision.disablefile", "/etc/mcollective/provisioner.disable")
        @puppet = config.pluginconf.fetch("provision.puppet", "/usr/bin/puppet agent")
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
        reply[:output] = %x[#{@puppet} --test --tags no_such_tag_here --color=none --summarize]
        reply[:exitcode] = $?.exitstatus

        # dont fail here if exitcode isnt 0, it'll always be non zero
      end

      # does a run of puppet with --environment bootstrap or similar
      action "bootstrap_puppet" do
        reply[:output] = %x[#{@puppet} --test --environment bootstrap --color=none --summarize]
        reply[:exitcode] = $?.exitstatus

        fail "Puppet returned #{reply[:exitcode]}" if [4,6].include?(reply[:exitcode])
      end

      # does a normal puppet run
      action "run_puppet" do
        reply[:output] = %x[#{@puppet} --test --color=none --summarize]
        reply[:exitcode] = $?.exitstatus

        fail "Puppet returned #{reply[:exitcode]}" if [4,6].include?(reply[:exitcode])
      end
      
      # runs puppet as a daemon
      action "daemonize_puppet" do
        reply[:output] = %x[#{@puppet} --onetime]
        reply[:exitcode] = $?.exitstatus

        fail "Puppet returned #{reply[:exitcode]}" if [4,6].include?(reply[:exitcode])
      end

      action "has_cert" do
        reply[:has_cert] = has_cert?
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

      action "disable_provisioner" do
        reply.fail! "Already disabled" if disabled?

        File.open(@disablefile, "w") {|f| f.puts Time.now}
        reply[:disablefile] = @disablefile

        reply.fail! "Failed to disable the provisioner" unless disabled?
      end

      action "is_disabled" do
        reply[:disabled] = disabled?
      end

      private
      def has_cert?
        File.exist?(@puppetcert)
      end

      def disabled?
        File.exist?(@disablefile)
      end

      def locked?
        File.exist?(@lockfile)
      end
    end
  end
end
