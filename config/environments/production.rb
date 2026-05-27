require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false
  config.log_level = :debug

  config.action_controller.perform_caching = true
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }
  config.active_storage.service = :cloudinary
  config.assume_ssl = true
  config.force_ssl = true
  config.action_controller.forgery_protection_origin_check = false

  $stdout.sync = true
  config.logger = ActiveSupport::Logger.new(STDOUT)
  config.log_tags = [ :request_id ]

  config.silence_healthcheck_path = "/up"
  config.active_support.report_deprecations = false
  config.cache_store = :solid_cache_store
  config.active_storage.analyzers = []
  config.active_storage.previewers = []
  config.active_storage.variant_processor = nil
  config.active_job.queue_adapter = :async
  config.action_mailer.default_url_options = { host: "example.com" }
  config.i18n.fallbacks = true
  config.active_record.dump_schema_after_migration = false
  config.active_record.attributes_for_inspect = [ :id ]
end