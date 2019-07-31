describe "Red Hat Cloud Services API" do
  # The following url helper is not defined without GET's on it
  let(:api_red_hat_cloud_services_url) { "#{api_url}/red_hat_cloud_services" }

  describe "POST" do
    it "/api/red_hat_cloud_services supports sync_platform action" do
      api_basic_authorize "red_hat_cloud_services"

      allow(Cfme::CloudServices::InventorySync).to receive("sync_queue").with(@user.userid, ["core"]) { 201 }
      post(api_red_hat_cloud_services_url, :params => { "action" => "sync_platform" })

      expect(response.parsed_body).to include(
        "success" => true,
        "message" => "Syncing Platform",
        "task_id" => "201"
      )
      expect(response).to have_http_status(:ok)
    end
  end
end
