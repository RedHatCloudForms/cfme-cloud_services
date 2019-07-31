module Api
  class RedHatCloudServicesController < BaseController
    def sync_platform_collection(_type, _data)
      desc = "Syncing Platform"
      task_id = Cfme::CloudServices::InventorySync.sync_queue(User.current_user.userid, ["core"])
      action_result(true, desc, :task_id => task_id)
    rescue => e
      action_result(false, e.to_s)
    end
  end
end
