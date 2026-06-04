Rails.application.routes.draw do
  devise_for :users
  get '/auth/:provider/callback', to: 'oauth_callbacks#create'
  get '/auth/failure', to: 'oauth_callbacks#failure'

  namespace :admin do
    root "dashboard#index"
    get "search", to: "search#index"
    resources :products do
      member do
        patch :restore
      end
    end
    resources :categories
    resources :orders, only: [:index, :show, :update]
    resources :users, only: [:index]
  end

  # config/routes.rb
  resource :cart, only: [:show] do
    collection do
      post   :add_item
      post   :buy_now
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
  post "/send-otp",   to: "otp_auth#send_otp",   as: :send_otp
  post "/resend-otp", to: "otp_auth#resend_otp", as: :resend_otp
  post "/verify-otp", to: "otp_auth#verify",     as: :verify_otp
  post "store-checkout-address",
       to: "checkout#store_address",
       as: :store_checkout_address
  get "contact",   to: "pages#contact"
  resources :contact_messages, only: [:create]
  get "shipping",  to: "pages#shipping"
  get "returns",   to: "pages#returns"
  get "size-guide",to: "pages#size_guide", as: :size_guide
  get "faq",       to: "pages#faq"
  get "privacy",   to: "pages#privacy"
  get "terms",     to: "pages#terms"
  get "cookies",   to: "pages#cookies"
  get "journal",   to: "pages#journal"
  get "search", to: "search#index"


  # Newsletter
  post "newsletter", to: "newsletter_subscriptions#create", as: :newsletter_subscriptions
  get "up" => "rails/health#show", as: :rails_health_check
end