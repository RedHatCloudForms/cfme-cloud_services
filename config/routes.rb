Rails.application.routes.draw do
  get '/red_hat_cloud_services', to: 'red_hat_cloud_services#show'
  get "red_hat_cloud_services/show_list", controller: 'red_hat_cloud_services', action: 'show_list'
  get "red_hat_cloud_services/show", controller: 'red_hat_cloud_services', action: 'show'
end
