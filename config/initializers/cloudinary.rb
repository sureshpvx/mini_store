# config/initializers/cloudinary.rb
Cloudinary.config do |config|
  config.upload_options = {
    overwrite: false,
    resource_type: "auto"  # auto-detects image/video
  }
end