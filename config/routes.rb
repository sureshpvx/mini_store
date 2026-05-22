Rails.application.routes.draw do
  devise_for :users

  namespace :admin do
    root "dashboard#index"
    resources :products
    resources :categories
    resources :orders, only: [:index, :show, :update]
  end

  resource :cart, only: [:show] do
    post :add_item
    patch "cart_items/:id/increase", to: "carts#increase_quantity", as: :increase_quantity
    patch "cart_items/:id/decrease", to: "carts#decrease_quantity", as: :decrease_quantity
    delete "cart_items/:id", to: "carts#remove_item", as: :remove_item
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