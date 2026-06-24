class OllamaClient
  OLLAMA_URL = ENV.fetch('OLLAMA_URL', 'http://localhost:11434')
  DEFAULT_MODEL = ENV.fetch('OLLAMA_MODEL', 'llama3.2:1b')

  # Website context for the AI assistant
  WEBSITE_CONTEXT = <<~CONTEXT
    You are the AI assistant for HYPE — a premium streetwear e-commerce store.
    
    About HYPE:
    - Premium streetwear brand with minimalist aesthetics
    - Products: Men, Women, and Accessories categories
    - 30+ items in the collection
    - New Arrivals drop regularly (SS/26 Collection currently active)
    - All products are premium quality
    
    Store Policies:
    - Shipping & Delivery available
    - Returns & Exchanges accepted
    - Size Guide available on the website
    - Contact page for support
    - FAQ page for common questions
    
    How you can help:
    - Answer questions about products, sizing, and styles
    - Help users navigate the website
    - Explain shipping, returns, and policies
    - Suggest products based on preferences
    - Be friendly, concise, and helpful
    
    Keep responses brief (2-3 sentences max) since they will be spoken aloud.
    If you don't know something specific, direct users to the Contact page or FAQ.
  CONTEXT

  class Error < StandardError; end
  class ConnectionError < Error; end
  class ModelError < Error; end

  def initialize(model: DEFAULT_MODEL)
    @model = model
    @uri = URI("#{OLLAMA_URL}/api/generate")
  end

  def generate(user_prompt)
    response = make_request(user_prompt)
    parse_response(response)
  rescue Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNREFUSED => e
    raise ConnectionError, "Cannot connect to Ollama: #{e.message}"
  rescue JSON::ParserError => e
    raise Error, "Invalid response from Ollama: #{e.message}"
  end

  private

  attr_reader :model, :uri

  def make_request(user_prompt)
    http = Net::HTTP.new(uri.host, uri.port)
    http.open_timeout = 30
    http.read_timeout = 60

    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request.body = {
      model: model,
      prompt: "#{WEBSITE_CONTEXT}\n\nUser: #{user_prompt}\nAssistant:",
      stream: false
    }.to_json

    http.request(request)
  end

  def parse_response(response)
    unless response.is_a?(Net::HTTPSuccess)
      raise Error, "Ollama returned #{response.code}: #{response.body}"
    end

    body = JSON.parse(response.body)
    body['response'] || raise(ModelError, "No response field in Ollama output")
  end
end
