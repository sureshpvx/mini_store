Rails.application.routes.draw do
  devise_for :users

  root "home#index"

  namespace :admin do
    root "dashboard#index"
    resources :products
    resources :categories

  end

  resources :products, only: [:index, :show]

  get "up" => "rails/health#show", as: :rails_health_check
end