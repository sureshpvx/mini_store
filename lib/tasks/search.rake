# lib/tasks/search.rake
namespace :search do
  desc "Rebuild pg_search index if empty"
  task setup: :environment do
    if PgSearch::Document.count == 0
      puts "Rebuilding search index..."
      [Product, Order, User, Category, ContactMessage, NewsletterSubscription].each do |model|
        PgSearch::Multisearch.rebuild(model)
      end
      puts "Done. #{PgSearch::Document.count} documents indexed."
    else
      puts "Search index already populated (#{PgSearch::Document.count} documents). Skipping rebuild."
    end
  end
end