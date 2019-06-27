class RedHatCloudServicesController < ApplicationController
  before_action :check_privileges
  after_action :cleanup_action

  def show_list
    @layout = 'red_hat_cloud_services'
    @page_title = _('red hat cloud services')
    render :show_list
  end

  helper do
    def layout_full_center
      "layouts/full_center_red_hat_cloud_services"
    end
  end
end
