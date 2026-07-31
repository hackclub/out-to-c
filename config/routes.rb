Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  get "auth/hackatime_callback" => "auth#hackatime_callback"
  get "auth/hca_callback" => "auth#hca_callback"
  get "auth/test" => "auth#test"
  get "auth/dev" => "auth#dev"

  post "voyage/new" => "voyage#new"
  post "voyage/delete" => "voyage#delete"
  post "voyage/add_hour" => "voyage#add_hour"

  root "home#index"
end
