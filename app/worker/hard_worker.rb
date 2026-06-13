class HardWorker
  include Sidekiq::Worker

  def perform(name, count)
    puts "Doing hard work for #{name}: #{count}"
    # You can do anything here - send emails, process images, etc.
  end
end