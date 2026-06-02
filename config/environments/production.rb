require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false
  config.log_level = :info

  config.action_controller.perform_caching = true

  # Gzip all responses
  config.middleware.use Rack::Deflater

  # Proper cache headers with encoding vary
  config.public_file_server.headers = {
    "Cache-Control" => "public, max-age=#{1.year.to_i}, immutable",
    "Vary" => "Accept-Encoding"
  }

  config.active_storage.service = :cloudinary
  config.assume_ssl = true
  config.force_ssl = true
  config.hosts << "hypee.shop"
  config.hosts << "www.hypee.shop"
  config.action_controller.forgery_protection_origin_check = false

  $stdout.sync = true
  config.logger = ActiveSupport::TaggedLogging.new(ActiveSupport::Logger.new(STDOUT))
  config.log_tags = [ :request_id ]

  config.silence_healthcheck_path = "/up"
  config.active_support.report_deprecations = false
  config.cache_store = :solid_cache_store
  config.active_storage.analyzers = []
  config.active_storage.previewers = []
  config.active_storage.variant_processor = nil
  config.active_job.queue_adapter = :async
  config.action_mailer.default_url_options = { host: "hypee.shop" }
  config.i18n.fallbacks = true
  config.active_record.dump_schema_after_migration = false
  config.active_record.attributes_for_inspect = [ :id ]
end