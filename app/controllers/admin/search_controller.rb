# app/controllers/admin/search_controller.rb
class Admin::SearchController < Admin::BaseController
  def index
    @query = params[:q].to_s.strip.downcase

    if @query.present?
      @results = PgSearch.multisearch(@query)
                         .includes(:searchable)
                         .limit(50)

      @products    = extract_results("Product")
      @orders      = extract_results("Order")
      @users       = extract_results("User")
      @categories  = extract_results("Category")
      @contacts    = extract_results("ContactMessage")
      @newsletters = extract_results("NewsletterSubscription")

      @total = @results.count
    else
      @total = 0
    end
  end

  private

  def extract_results(type)
    @results.select { |r| r.searchable_type == type }.map(&:searchable)
  end
end