Rails.application.routes.draw do
  devise_for :users

  root "home#index"

  namespace :admin do
    root "dashboard#index"
  end

  get "up" => "rails/health#show", as: :rails_health_check
end