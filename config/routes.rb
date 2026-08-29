Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  get "auth/hackatime_callback" => "auth#hackatime_callback"
  get "auth/hca_callback" => "auth#hca_callback"
  get "auth/test" => "auth#test"
  get "auth/dev" => "auth#dev"
  
  get "wipe_slack_convo" => "voyage#wipe_slack_convo"
  get "wipe_slack_channel/:id" => "voyage#wipe_slack_channel"
  post "voyage/new" => "voyage#new"
  post "voyage/delete" => "voyage#delete"
  post "voyage/delete_force" => "voyage#delete_force"
  post "voyage/add_hour" => "voyage#add_hour"
  post "voyage/price" => "voyage#price"
  post "voyage/merchant" => "voyage#merchant"
  post "voyage/ship" => "voyage#ship"

  get "admin" => "admin#index"
  get "admin/reload_reviewer_list" => "admin#reload_reviewer_list"
  get "admin/edit/:id", to: "admin#edit"
  get "admin/raw/:id", to: "admin#raw"
  post "admin/submit_edit", to: "admin#submit_edit"

  get "reviewer" => "reviewer#index"
  get "reviewer/edit/:id" => "reviewer#edit"
  post "reviewer/submit_edit" => "reviewer#submit_edit"
  
  get "docs" => "home#docs"
  root "home#index"
end
