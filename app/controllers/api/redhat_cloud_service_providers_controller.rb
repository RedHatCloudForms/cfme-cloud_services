module Api
  class RedhatCloudServiceProvidersController < BaseController
    def redhat_cloud_service_providers_search_conditions
      { :type => provider_types }
    end

    def find_redhat_cloud_service_providers(id)
      collection_type = :redhat_cloud_service_providers
      klass = collection_class(collection_type)
      provider = find_resource(klass, "id", id)
      provider = filter_resource(provider, collection_type, klass)
      raise NotFoundError, "Invalid RedHat Cloud Service Provider id #{id} specified" unless provider_types.include?(provider.type)

      provider
    end

    def sync_resource(type, id, data)
      provider = find_redhat_cloud_service_providers(id)
      $log.info "XXXXXX - #{type}, provider type = #{provider.type} id = #{provider.id}, #{data}"
    end

    private

    def provider_types
      Cfme::CloudServices::ManifestFetcher.fetch["manifest"].keys.reject { |k| k == "core" }.uniq
    end
  end
end
