# app/controllers/newsletter_subscriptions_controller.rb
class NewsletterSubscriptionsController < ApplicationController
  def create
    @subscription = NewsletterSubscription.new(email: params[:email])

    if @subscription.save
      redirect_back fallback_location: root_path, notice: "Welcome to the inner circle."
    else
      redirect_back fallback_location: root_path, alert: "Please enter a valid email address."
    end
  end
end