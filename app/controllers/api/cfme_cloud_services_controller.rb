module Api
  class CfmeCloudServicesController < BaseController
    def sync_resource(type, id, data)
      $log.info "XXXXXX - #{type}, #{id}, #{data}"
    end
  end
end
