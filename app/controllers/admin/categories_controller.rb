class Admin::CategoriesController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin

  def index
    @categories = Category.includes(:subcategories).where(parent_id: nil)
    @category = Category.new
  end

  def create
    @category = Category.new(category_params)

    if @category.save
      redirect_to admin_categories_path, notice: "Category created"
    else
      @categories = Category.where(parent_id: nil)
      render :index, status: :unprocessable_entity
    end
  end

  private

  def category_params
    params.require(:category).permit(:name, :parent_id)
  end

  def require_admin
    redirect_to root_path unless current_user.admin?
  end
end