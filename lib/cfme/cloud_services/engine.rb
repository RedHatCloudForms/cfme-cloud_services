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

      initializer 'plugin' do
        Menu::CustomLoader.register(
          Menu::Section.new(:red_hat_cloud_services, N_("Red Hat Cloud"), 'pficon ff ff-red-hat-logo', [
            Menu::Item.new('red_hat_cloud_services', N_('Services'), 'red_hat_cloud_services', {:feature => 'red_hat_cloud_services', :any => true}, '/red_hat_cloud_services/show'),
            Menu::Item.new('red_hat_cloud_services_providers', N_('Providers'), 'red_hat_cloud_services_providers', {:feature => 'red_hat_cloud_services', :any => true}, '/red_hat_cloud_services/show_list')
         ])
        )
      end
    end
  end
end
