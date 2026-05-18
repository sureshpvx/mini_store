class ProductsController < ApplicationController
  def index
    @products = Product.includes(:category)

    # 🔍 SEARCH
    if params[:query].present?
      q = "%#{params[:query]}%"
      @products = @products.where(
        "products.name ILIKE :q OR products.description ILIKE :q", q: q
      )
    end

    # 🎯 FILTERS
    case params[:filter]
    when "new"
      @products = @products.where("products.created_at >= ?", 7.days.ago)

    when "men", "women", "accessories"
      # This handles Men, Women, and Accessories using the same logic
      parent = Category.find_by("name ILIKE ?", params[:filter])

      if parent
        # Find the IDs of the parent and all its direct children
        category_ids = [parent.id] + Category.where(parent_id: parent.id).pluck(:id)
        @products = @products.where(category_id: category_ids)
      end

    when "all"
      # no filter needed
    end

    # 📌 SORT
    @products = @products.order(created_at: :desc)
  end

  def show
    @product = Product.friendly.find(params[:id])  end
end