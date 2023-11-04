require 'web/api'
require 'rack/test'

RSpec.describe Web::Api do
  include Rack::Test::Methods

  let(:app) { described_class.new }

  it 'responds to /status with a 200' do
    get '/status'

    expect(last_response.status).to eq(200)
  end
end
