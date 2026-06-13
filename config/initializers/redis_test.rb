# config/initializers/redis_test.rb

begin
  redis = Redis.new(url: ENV["REDIS_URL"])
  Rails.logger.info "Redis ping: #{redis.ping}"
rescue => e
  Rails.logger.error "Redis connection failed: #{e.message}"
end