require 'net/http'
require 'json'

class AiClient
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

  GROQ_MODELS = {
    'llama-3.3-70b-versatile' => 'llama-3.3-70b-versatile',
    'llama-3.1-8b-instant' => 'llama-3.1-8b-instant',
    'mixtral-8x7b-32768' => 'mixtral-8x7b-32768',
    'gemma2-9b-it' => 'gemma2-9b-it'
  }.freeze

  def initialize
    @provider = determine_provider
  end

  def generate(user_prompt)
    case @provider
    when :groq
      call_groq(user_prompt)
    when :ollama
      call_ollama(user_prompt)
    else
      raise Error, "No AI provider configured. Set GROQ_API_KEY or run Ollama locally."
    end
  end

  private

  def determine_provider
    return :groq if ENV['GROQ_API_KEY'].present?
    return :ollama if ollama_running?
    nil
  end

  def ollama_running?
    Net::HTTP.get(URI('http://localhost:11434/api/tags'))
    true
  rescue
    false
  end

  def call_groq(user_prompt)
    api_key = ENV['GROQ_API_KEY']
    model = ENV.fetch('GROQ_MODEL', 'llama-3.3-70b-versatile')
    
    uri = URI('https://api.groq.com/openai/v1/chat/completions')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 30
    http.read_timeout = 60

    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{api_key}"
    request['Content-Type'] = 'application/json'
    request.body = {
      model: model,
      messages: [
        { role: 'system', content: WEBSITE_CONTEXT },
        { role: 'user', content: user_prompt }
      ],
      temperature: 0.7,
      max_tokens: 500
    }.to_json

    response = http.request(request)
    
    unless response.is_a?(Net::HTTPSuccess)
      raise Error, "Groq returned #{response.code}: #{response.body}"
    end

    body = JSON.parse(response.body)
    content = body.dig('choices', 0, 'message', 'content')
    content || raise(Error, "Empty response from Groq")
  rescue Net::OpenTimeout, Net::ReadTimeout => e
    raise ConnectionError, "Groq timeout: #{e.message}"
  rescue JSON::ParserError => e
    raise Error, "Invalid response from Groq: #{e.message}"
  end

  def call_ollama(user_prompt)
    uri = URI(ENV.fetch('OLLAMA_URL', 'http://localhost:11434/api/generate'))
    http = Net::HTTP.new(uri.host, uri.port)
    http.open_timeout = 30
    http.read_timeout = 60

    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/json'
    request.body = {
      model: ENV.fetch('OLLAMA_MODEL', 'llama3.2:1b'),
      prompt: "#{WEBSITE_CONTEXT}\n\nUser: #{user_prompt}\nAssistant:",
      stream: false
    }.to_json

    response = http.request(request)
    
    unless response.is_a?(Net::HTTPSuccess)
      raise Error, "Ollama returned #{response.code}"
    end

    body = JSON.parse(response.body)
    body['response'] || raise(Error, "No response from Ollama")
  rescue Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNREFUSED => e
    raise ConnectionError, "Cannot connect to Ollama: #{e.message}"
  rescue JSON::ParserError => e
    raise Error, "Invalid response from Ollama: #{e.message}"
  end
end
