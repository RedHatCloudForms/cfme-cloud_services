describe "Red Hat Cloud Service Providers API" do
  before do
    # Let's stub the ManifestFetcher to only allow for Vmware InfraManager
    allow(Cfme::CloudServices::ManifestFetcher).to receive("fetch") {
      { "manifest" => { "ManageIQ::Providers::Vmware::InfraManager" => {}}}
    }
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

    it "/api/red_hat_cloud_service_providers sync action fails without provider_ids" do
      api_basic_authorize "red_hat_cloud_services"

      post(api_red_hat_cloud_service_providers_url,
           :params => {
             "action" => "sync"
           })

      expect(response.parsed_body).to include(
        "success" => false,
        "message" => "Must specify a list of provider ids via \"provider_ids\""
      )
      expect(response).to have_http_status(:ok)
    end

    it "/api/red_hat_cloud_service_providers sync action fails with invalid provider_ids" do
      api_basic_authorize "red_hat_cloud_services"

      ems1 = FactoryBot.create(:ems_vmware, :name => "sample vmware1")
      ems2 = FactoryBot.create(:ems_vmware, :name => "sample vmware2")

      post(api_red_hat_cloud_service_providers_url,
           :params => {
             "action"       => "sync",
             "provider_ids" => ["9999", ems1.id.to_s, ems2.id.to_s, "8888"]
           })

      expect(response.parsed_body).to include(
        "success" => false,
        "message" => "Invalid Provider ids 8888, 9999 specified"
      )
      expect(response).to have_http_status(:ok)
    end

    it "/api/red_hat_cloud_service_providers sync action succeeds with valid provider ids specified" do
      api_basic_authorize "red_hat_cloud_services"

      ems1 = FactoryBot.create(:ems_vmware, :name => "sample vmware1")
      ems2 = FactoryBot.create(:ems_vmware, :name => "sample vmware2")

      allow(Cfme::CloudServices::InventorySync).to receive("sync_queue")
        .with(@user.userid, [["ExtManagementSystem", ems1.id], ["ExtManagementSystem", ems2.id]]) { 104 }

      post(api_red_hat_cloud_service_providers_url,
           :params => {
             "action"       => "sync",
             "provider_ids" => [ems1.id.to_s, ems2.id.to_s]
           })

      expect(response.parsed_body).to include(
        "success" => true,
        "message" => "Syncing Providers ids: #{ems1.id}, #{ems2.id}",
        "task_id" => "104"
      )
      expect(response).to have_http_status(:ok)
    end

    it "/api/red_hat_cloud_service_providers sync_all action fails if there are no providers to sync" do
      api_basic_authorize "red_hat_cloud_services"

      post(api_red_hat_cloud_service_providers_url,
           :params => {
             "action" => "sync_all"
           })

      expect(response.parsed_body).to include(
        "success" => false,
        "message" => "There are no Providers to Sync"
      )
      expect(response).to have_http_status(:ok)
    end

    it "/api/red_hat_cloud_service_providers sync_all action succeeds with providers available" do
      api_basic_authorize "red_hat_cloud_services"

      ems1 = FactoryBot.create(:ems_vmware, :name => "sample vmware1")
      ems2 = FactoryBot.create(:ems_vmware, :name => "sample vmware2")

      allow(Cfme::CloudServices::InventorySync).to receive("sync_queue")
        .with(@user.userid, [["ExtManagementSystem", ems1.id], ["ExtManagementSystem", ems2.id]]) { 105 }

      post(api_red_hat_cloud_service_providers_url,
           :params => {
             "action" => "sync_all"
           })

      expect(response.parsed_body).to include(
        "success" => true,
        "message" => "Syncing All Providers",
        "task_id" => "105"
      )
      expect(response).to have_http_status(:ok)
    end
  end
end
