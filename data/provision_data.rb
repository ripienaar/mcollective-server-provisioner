module MCollective
  module Data
    class Provision_data<Base
      activate_when do
        !File.exist?(Config.instance.pluginconf.fetch("provision.disablefile", "/etc/mcollective/provisioner.disable"))
      end

      query do |q|
        result[:locked] = locked?
        result[:disabled] = disabled?
      end

      def disabled?
        File.exist?(Config.instance.pluginconf.fetch("provision.disablefile", "/etc/mcollective/provisioner.disable"))
      end

      def locked?
        File.exist?(Config.instance.pluginconf.fetch("provision.lockfile", "/etc/mcollective/provisioner.lock"))
      end
    end
  end
end
