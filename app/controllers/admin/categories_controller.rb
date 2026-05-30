class Admin::CategoriesController < Admin::BaseController
  before_action :set_category, only: [:update, :destroy]

  def index
    @categories = Category.includes(:subcategories)
                          .where(parent_id: nil)

    @category = Category.new
  end

  def create
    @category = Category.new(category_params)

    if @category.save
      redirect_to admin_categories_path,
                  notice: "Category created"
    else
      @categories = Category.includes(:subcategories)
                            .where(parent_id: nil)

      render :index,
             status: :unprocessable_entity
    end
  end

  def update
    if @category.update(category_params)
      redirect_to admin_categories_path,
                  notice: "Category updated"
    else
      @categories = Category.includes(:subcategories)
                            .where(parent_id: nil)

      render :index,
             status: :unprocessable_entity
    end
  end

  def destroy

    if @category.subcategories.exists?

      redirect_to admin_categories_path,
                  alert: "Delete subcategories first"

      return
    end

    @category.destroy

    redirect_to admin_categories_path,
                notice: "Category deleted"
  end

  private

  def set_category
    @category = Category.find(params[:id])
  end

  def category_params
    params.require(:category)
          .permit(:name, :parent_id)
  end

  def require_admin
    redirect_to root_path unless current_user.admin?
  end
end