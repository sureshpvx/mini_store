class ProductsController < ApplicationController

  def index

    @products = Product.includes(
      :category,
      images_attachments: :blob
    )

    # 🔍 SEARCH
    if params[:query].present?

      q = "%#{params[:query]}%"

      @products = @products.where(
        "products.name ILIKE :q
         OR products.description ILIKE :q",
        q: q
      )

    end

    # 🎯 FILTERS
    case params[:filter]

    when "new"

      @products = @products.where(
        "products.created_at >= ?",
        7.days.ago
      )

    when "men", "women", "accessories"

      parent = Category.find_by(
        "name ILIKE ?",
        params[:filter]
      )

      if parent

        category_ids =
          [parent.id] +
          Category.where(
            parent_id: parent.id
          ).pluck(:id)

        @products = @products.where(
          category_id: category_ids
        )

      end

    when "all"
      # no filter needed

    end

    # 📌 SORT
    @products = @products.order(
      created_at: :desc
    )

  end

  def show

    @product = Product.includes(
      :category,
      images_attachments: :blob
    ).friendly.find(params[:id])

  end

end