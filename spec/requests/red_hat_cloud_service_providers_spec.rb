module Cfme
  module CloudServices
    module InventorySync; end
  end
end

describe "Red Hat Cloud Service Providers API" do
  before do
    # Let's stub the ManifestFetcher to only allow for Vmware InfraManager
    allow(Cfme::CloudServices::ManifestFetcher.fetch["manifest"]).to receive("keys") { ["ManageIQ::Providers::Vmware::InfraManager"] }
  end

  describe "GET" do
    it "/api/red_hat_cloud_service_providers returns supported providers" do
      api_basic_authorize "red_hat_cloud_services"

      ems1 = FactoryBot.create(:ems_vmware,    :name => "sample vmware1")
      ems2 = FactoryBot.create(:ems_vmware,    :name => "sample vmware2")
      FactoryBot.create(:ems_openstack, :name => "sample openstack1")

      get(api_red_hat_cloud_service_providers_url, :params => { :expand => "resources"})

      expect(response.parsed_body["resources"].collect { |provider| provider["id"] }).to match_array(
        [ems1.id.to_s, ems2.id.to_s]
      )
      expect(response).to have_http_status(:ok)
    end

    it "/api/red_hat_cloud_service_providers/:id succeeds for supported provider" do
      api_basic_authorize "red_hat_cloud_services"

      FactoryBot.create(:ems_openstack, :name => "sample openstack1")
      ems2 = FactoryBot.create(:ems_vmware, :name => "sample vmware1")

      get(api_red_hat_cloud_service_provider_url(nil, ems2))
      expect(response.parsed_body).to include(
        "id"   => ems2.id.to_s,
        "name" => "sample vmware1"
      )
      expect(response).to have_http_status(:ok)
    end

    it "/api/red_hat_cloud_service_providers/:id failed for unsupported provider" do
      api_basic_authorize "red_hat_cloud_services"

      ems1 = FactoryBot.create(:ems_openstack, :name => "sample openstack1")
      FactoryBot.create(:ems_vmware, :name => "sample vmware1")

      get(api_red_hat_cloud_service_provider_url(nil, ems1))

      expect(response.parsed_body).to include(
        "error" => a_hash_including(
          "kind"    => "not_found",
          "message" => a_string_including("Invalid Provider id:#{ems1.id} specified")
        )
      )
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST" do
    it "/api/red_hat_cloud_service_providers/:id sync action" do
      api_basic_authorize "red_hat_cloud_services"

      ems1 = FactoryBot.create(:ems_vmware, :name => "sample vmware1")

      allow(Cfme::CloudServices::InventorySync).to receive("sync_queue").with(@user.userid, ems1) { 101 }
      post(api_red_hat_cloud_service_provider_url(nil, ems1), :params => { "action" => "sync" })

      expect(response.parsed_body).to include(
        "success" => true,
        "message" => "Syncing Provider id:#{ems1.id} name:'#{ems1.name}'",
        "task_id" => "101"
      )
      expect(response).to have_http_status(:ok)
    end

    it "/api/red_hat_cloud_service_providers bulk sync action" do
      api_basic_authorize "red_hat_cloud_services"

      ems1 = FactoryBot.create(:ems_vmware, :name => "sample vmware1")
      ems2 = FactoryBot.create(:ems_vmware, :name => "sample vmware2")

      allow(Cfme::CloudServices::InventorySync).to receive("sync_queue").with(@user.userid, ems1) { 102 }
      allow(Cfme::CloudServices::InventorySync).to receive("sync_queue").with(@user.userid, ems2) { 103 }

      post(api_red_hat_cloud_service_providers_url,
           :params => {
             "action"    => "sync",
             "resources" => [{ "id" => ems1.id.to_s }, { "id" => ems2.id.to_s }]
           })

      expect(response.parsed_body).to include(
        "results" => [
          a_hash_including(
            "success" => true,
            "message" => "Syncing Provider id:#{ems1.id} name:'#{ems1.name}'",
            "task_id" => "102"
          ), a_hash_including(
            "success" => true,
            "message" => "Syncing Provider id:#{ems2.id} name:'#{ems2.name}'",
            "task_id" => "103"
          )
        ]
      )
      expect(response).to have_http_status(:ok)
    end
  end
end
