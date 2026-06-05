class ProductsController < ApplicationController
  include Pagy::Backend

  def index
    products = Product.active.with_attached_images.includes(:category).order(created_at: :desc)

    if params[:filter].present?
      case params[:filter].downcase
      when "new"
        products = products.where("created_at >= ?", 7.days.ago)
      when "men", "women", "accessories"
        # Find parent category
        parent = Category.find_by("LOWER(name) = ?", params[:filter])
        if parent
          # Get parent + all children IDs
          category_ids = [parent.id] + Category.where(parent_id: parent.id).pluck(:id)
          products = products.where(category_id: category_ids)
        end
      else
        # Fallback: exact category name match
        category = Category.find_by("LOWER(name) = ?", params[:filter])
        products = products.where(category: category) if category
      end
    end

    @pagy, @products = pagy(products, limit: 12)
    @product_count = @pagy.count
  end

  def show
    @product = Product.active.with_attached_images.includes(:category).friendly.find(params[:id])
  end
end