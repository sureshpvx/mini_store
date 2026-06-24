require 'rails_helper'
require 'webmock/rspec'

RSpec.describe 'Voice AI Bot', type: :request do
  let(:ollama_url) { 'http://localhost:11434' }

  before do
    stub_request(:get, "#{ollama_url}/api/tags")
      .to_return(status: 200, body: { models: [] }.to_json)
    
    stub_request(:post, "#{ollama_url}/api/generate")
      .to_return(
        status: 200,
        body: { response: 'Hello! How can I help you today?' }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  describe 'GET /voice' do
    it 'returns success' do
      get voice_path
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST /voice/message' do
    context 'with valid message' do
      it 'returns AI reply as JSON' do
        post voice_message_path, params: { message: 'Hello bot' }

        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)['reply']).to eq('Hello! How can I help you today?')
      end
    end

    context 'with empty message' do
      it 'returns bad request' do
        post voice_message_path, params: { message: '' }

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)['error']).to eq('Message cannot be empty')
      end
    end

    context 'when AI is down' do
      before do
        stub_request(:post, "#{ollama_url}/api/generate")
          .to_return(status: 500, body: 'Error')
      end

      it 'returns service unavailable' do
        post voice_message_path, params: { message: 'Hello' }

        expect(response).to have_http_status(:internal_server_error)
      end
    end
  end
end
