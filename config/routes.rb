Rails.application.routes.draw do
  devise_for :users

  namespace :admin do
    root "dashboard#index"
    resources :products
    resources :categories
    resources :orders, only: [:index, :show, :update]
  end

  # config/routes.rb
  resource :cart, only: [:show] do
    collection do
      post   :add_item
      patch  :increase_quantity
      patch  :decrease_quantity
      delete :remove_item
    end
  end

  resources :addresses
  get "/checkout", to: "checkout#show"

  resources :orders, only: [:index, :show, :create] do
    member do
      get :payment
      post :verify_payment
    end
  end
  post "/checkout", to: "orders#create"

  resources :products, only: [:index, :show]

  root "home#index"
  get  "/otp-login", to: "otp_auth#new"
  post "/send-otp", to: "otp_auth#send_otp"
  post "/verify-otp", to: "otp_auth#verify"
  post "store-checkout-address",
       to: "checkout#store_address",
       as: :store_checkout_address
  get "up" => "rails/health#show", as: :rails_health_check
end