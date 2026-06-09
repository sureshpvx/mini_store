# app/controllers/sitemap_controller.rb
class SitemapController < ApplicationController
  def index
    @products = Product.all
    @categories = Category.all
    respond_to do |format|
      format.xml
    end
  end
end