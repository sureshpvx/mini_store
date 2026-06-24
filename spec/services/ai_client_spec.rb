require 'rails_helper'
require 'webmock/rspec'

RSpec.describe AiClient do
  let(:client) { described_class.new }
  let(:ollama_url) { 'http://localhost:11434' }

  describe '#generate with Ollama' do
    context 'when Ollama is running' do
      before do
        stub_request(:get, "#{ollama_url}/api/tags")
          .to_return(status: 200, body: { models: [] }.to_json)
        
        stub_request(:post, "#{ollama_url}/api/generate")
          .to_return(
            status: 200,
            body: { response: 'Hello from Ollama!' }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns AI response' do
        result = client.generate('Say hello')
        expect(result).to eq('Hello from Ollama!')
      end
    end

    context 'when no provider is available' do
      before do
        # Stub Ollama to appear down
        stub_request(:get, "#{ollama_url}/api/tags")
          .to_raise(Errno::ECONNREFUSED)
      end

      it 'raises an error' do
        expect { client.generate('Say hello') }
          .to raise_error(AiClient::Error, /No AI provider configured/)
      end
    end
  end
end
