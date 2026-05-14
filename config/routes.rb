Rails.application.routes.draw do
  devise_for :users

  root "home#index"

  namespace :admin do
    root "dashboard#index"
    resources :products
    resources :categories
  end

  resource :cart, only: [:show] do
    post :add_item
    patch "cart_items/:id/increase", to: "carts#increase_quantity", as: :increase_quantity
    patch "cart_items/:id/decrease", to: "carts#decrease_quantity", as: :decrease_quantity
    delete "cart_items/:id", to: "carts#remove_item", as: :remove_item
  end

  resources :orders, only: [:index, :show, :create]
  post "/checkout", to: "orders#create"

  resources :products, only: [:index, :show]

  get "up" => "rails/health#show", as: :rails_health_check
end