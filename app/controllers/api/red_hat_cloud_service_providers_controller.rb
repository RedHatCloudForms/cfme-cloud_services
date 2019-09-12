module Api
  class RedHatCloudServiceProvidersController < BaseController
    def red_hat_cloud_service_providers_search_conditions
      { :type => provider_types }
    end

    def find_red_hat_cloud_service_providers(id)
      collection_type = :red_hat_cloud_service_providers
      klass = collection_class(collection_type)
      provider = find_resource(klass, "id", id)
      provider = filter_resource(provider, collection_type, klass)
      raise NotFoundError, "Invalid Provider id:#{id} specified" unless provider_types.include?(provider.type)

      provider
    end

    def sync_resource(_type, id, _data)
      provider = find_red_hat_cloud_service_providers(id)
      desc = "Syncing #{provider_ident(provider)}"
      task_id = Cfme::CloudServices::InventorySync.sync_queue(User.current_user.userid, provider)
      action_result(true, desc, :task_id => task_id)
    rescue => e
      action_result(false, e.to_s)
    end

    def sync_collection(type, data)
      provider_ids = data["provider_ids"]
      provider_ids = provider_ids.map(&:to_i).uniq if provider_ids
      raise "Must specify a list of provider ids via \"provider_ids\"" if provider_ids.blank?

      invalid_provider_ids = provider_ids - find_provider_ids(type)
      raise "Invalid Provider ids #{invalid_provider_ids.sort.join(', ')} specified" if invalid_provider_ids.present?

      desc = "Syncing Providers ids: #{provider_ids.join(', ')}"
      targets = provider_ids_to_targets(provider_ids)
      task_id = Cfme::CloudServices::InventorySync.sync_queue(User.current_user.userid, targets)
      action_result(true, desc, :task_id => task_id)
    rescue => e
      action_result(false, e.to_s)
    end

    def sync_all_collection(type, _data)
      provider_ids = find_provider_ids(type)
      raise "There are no Providers to Sync" if provider_ids.blank?

      desc = "Syncing All Providers"
      targets = provider_ids_to_targets(provider_ids)
      task_id = Cfme::CloudServices::InventorySync.sync_queue(User.current_user.userid, targets)
      action_result(true, desc, :task_id => task_id)
    rescue => e
      action_result(false, e.to_s)
    end

    private

    def provider_ident(provider)
      "Provider id:#{provider.id} name:'#{provider.name}'"
    end

    def find_provider_ids(type)
      providers, _ = collection_search(false, type, collection_class(type))
      providers ? providers.ids.sort : []
    end

    def provider_types
      manifest = Cfme::CloudServices::ManifestFetcher.fetch["manifest"] || {}
      manifest.keys.reject { |k| ["core", "version"].include?(k) }.uniq
    end

    def provider_ids_to_targets(provider_ids)
      provider_ids.map { |id| ["ExtManagementSystem", id] }
    end
  end
end
