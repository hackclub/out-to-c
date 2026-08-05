Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  get "auth/hackatime_callback" => "auth#hackatime_callback"
  get "auth/hca_callback" => "auth#hca_callback"
  get "auth/test" => "auth#test"
  get "auth/dev" => "auth#dev"
  
  get "voyage/wipe_slack_convo" => "voyage#wipe_slack_convo"
  post "voyage/new" => "voyage#new"
  post "voyage/delete" => "voyage#delete"
  post "voyage/delete_force" => "voyage#delete_force"
  post "voyage/add_hour" => "voyage#add_hour"
  post "voyage/price" => "voyage#price"
  post "voyage/ship" => "voyage#ship"

  get "admin" => "admin#index"

  root "home#index"
end
