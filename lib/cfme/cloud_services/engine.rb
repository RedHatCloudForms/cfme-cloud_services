module Cfme
  module CloudServices
    class Engine < ::Rails::Engine
      isolate_namespace Cfme::CloudServices

      config.autoload_paths << root.join('lib').to_s

      def self.vmdb_plugin?
        true
      end

      def self.plugin_name
        _('Red Hat Cloud Services')
      end
    end
  end
end
