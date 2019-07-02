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
          Menu::Section.new(:red_hat_cloud_services, N_("Red Hat Cloud"), 'pficon rh-icon', [
           Menu::Item.new('services', N_('Services'), 'red_hat_cloud_services', {:feature => 'red_hat_cloud_services', :any => true}, '/red_hat_cloud_services/show'),
           Menu::Item.new('services', N_('Providers'), 'red_hat_cloud_services', {:feature => 'red_hat_cloud_services', :any => true}, '/red_hat_cloud_services/show_list')
         ])
        )
      end
    end
  end
end
