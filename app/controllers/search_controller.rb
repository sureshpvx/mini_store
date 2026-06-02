# app/controllers/search_controller.rb
class SearchController < ApplicationController
  def index
    @query = params[:q].to_s.strip.downcase
    @products = if @query.present?
                  Product.search(@query).limit(12).with_attached_images
                else
                  Product.none
                end
  end
end