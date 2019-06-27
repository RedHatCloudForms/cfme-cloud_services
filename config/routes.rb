#RedHatCloudServices::Engine.routes.draw do
Rails.application.routes.draw do
  get '/red_hat_cloud_services', to: 'red_hat_cloud_services#show_list'
  get "red_hat_cloud_services/show_list", controller: 'red_hat_cloud_services', action: 'show_list'

end
