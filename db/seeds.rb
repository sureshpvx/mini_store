# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
# Ensure these users exist and are updated when seeds are re-run (idempotent)
[
  { email: "admin@example.com", password: "password123", role: "admin" },
  { email: "user@example.com", password: "password123", role: "customer" }
].each do |attrs|
  user = User.find_or_initialize_by(email: attrs[:email])
  # assign_attributes will update password/role if changed; save! persists the record
  user.assign_attributes(password: attrs[:password], role: attrs[:role])
  user.save!
end
