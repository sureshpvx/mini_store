require 'rails_helper'
require 'webmock/rspec'

RSpec.describe OllamaClient do
  let(:client) { described_class.new }
  let(:ollama_url) { 'http://localhost:11434' }

  before do
    stub_const('OllamaClient::OLLAMA_URL', ollama_url)
    stub_const('OllamaClient::DEFAULT_MODEL', 'llama3.2:1b')
  end

  describe '#generate' do
    context 'when Ollama returns a successful response' do
      before do
        stub_request(:post, "#{ollama_url}/api/generate")
          .with(
            body: hash_including({
              model: 'llama3.2:1b',
              stream: false
            })
          )
          .to_return(
            status: 200,
            body: { response: 'Hello there! How can I help?' }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns the AI response text' do
        result = client.generate('Say hello')
        expect(result).to eq('Hello there! How can I help?')
      end

      it 'includes website context in the prompt' do
        client.generate('Say hello')
        expect(WebMock).to have_requested(:post, "#{ollama_url}/api/generate")
          .with(body: hash_including({ model: 'llama3.2:1b' }))
      end
    end

    context 'when Ollama returns an error status' do
      before do
        stub_request(:post, "#{ollama_url}/api/generate")
          .to_return(status: 500, body: 'Internal Server Error')
      end

      it 'raises an OllamaClient::Error' do
        expect { client.generate('Say hello') }
          .to raise_error(OllamaClient::Error, /Ollama returned 500/)
      end
    end

    context 'when Ollama is not running' do
      before do
        stub_request(:post, "#{ollama_url}/api/generate")
          .to_raise(Errno::ECONNREFUSED)
      end

      it 'raises a ConnectionError' do
        expect { client.generate('Say hello') }
          .to raise_error(OllamaClient::ConnectionError, /Cannot connect to Ollama/)
      end
    end

    context 'when response has no response field' do
      before do
        stub_request(:post, "#{ollama_url}/api/generate")
          .to_return(
            status: 200,
            body: { done: true }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'raises a ModelError' do
        expect { client.generate('Say hello') }
          .to raise_error(OllamaClient::ModelError, /No response field/)
      end
    end
  end
end
