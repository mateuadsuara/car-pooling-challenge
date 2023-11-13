require 'rack/test'
require 'json'

require 'web/api'
require 'car_pooling/service'

RSpec.describe Web::Api do
  include Rack::Test::Methods

  ALL_METHODS = ["GET", "HEAD", "POST", "PUT", "DELETE", "CONNECT", "OPTIONS", "TRACE", "PATCH"]

  let(:service_class) { spy(CarPooling::Service.class) }
  let(:service) { spy(CarPooling::Service) }
  let(:app) { described_class.new(service_class) }

  before(:each) do
    allow(service_class).to receive(:new)
      .and_return(service)
  end

  describe '/status' do
    valid_method = "GET"

    it "responds 200 for #{valid_method} requests" do
      custom_request(valid_method, '/status')

      expect(last_response.status).to eq(200)
    end

    (ALL_METHODS - [valid_method]).each do |invalid_method|
      it "responds 405 for #{invalid_method} requests" do
        custom_request(invalid_method, "/status")

        expect(last_response.status).to eq(405)
      end
    end
  end

  describe '/cars' do
    valid_method = "PUT"

    def request_load_cars(body, content_type: "application/json", method: "PUT")
      custom_request(method, '/cars', body, "CONTENT_TYPE" => content_type)
    end

    it "responds 200 for #{valid_method} requests and registered correctly" do
      cars = [
        {
          id: 1,
          seats: 4
        },
        {
          id: 2,
          seats: 6
        }
      ]
      request_load_cars(cars.to_json)

      expect(last_response.status).to eq(200)
      expect(service_class).to have_received(:new)
        .with({1=>4, 2=>6})
    end

    (ALL_METHODS - [valid_method]).each do |invalid_method|
      it "responds 405 for #{invalid_method} requests" do
        cars = [
          {
            id: 1,
            seats: 4
          }
        ]
        request_load_cars(cars.to_json, method: invalid_method)

        expect(last_response.status).to eq(405)
      end
    end

    it 'responds 400 for invalid content type' do
      cars = [
        {
          id: 1,
          seats: 4
        }
      ]
      request_load_cars(cars.to_json, content_type: "::invalid_content_type::")

      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq("expected content type to be json")
    end

    it 'responds 400 for invalid json' do
      request_load_cars('::invalid::')

      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq("invalid json\nunexpected token at '::invalid::'")
    end

    it 'responds 400 for other container types' do
      request_load_cars({}.to_json)

      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq("expected a list")
    end

    it 'responds 400 for other element types' do
      request_load_cars([true].to_json)

      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq("expected the element on index 0 to be an object")
    end

    it 'responds 400 for missing id' do
      cars = [
        {
          seats: 4
        }
      ]
      request_load_cars(cars.to_json)

      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq("missing id attribute on index 0")
    end

    it 'responds 400 for missing seats' do
      cars = [
        {
          id: 1
        }
      ]
      request_load_cars(cars.to_json)

      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq("missing seats attribute on index 0")
    end

    it 'responds 400 for non-numeric seats' do
      cars = [
        {
          id: 1,
          seats: 5.3
        }
      ]
      request_load_cars(cars.to_json)

      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq("expected seats to be an integer on index 0")
    end

    it 'responds 400 for duplicate ids' do
      cars = [
        {
          id: 1,
          seats: 4
        },
        {
          id: 1,
          seats: 6
        }
      ]

      request_load_cars(cars.to_json)

      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq("duplicate id: 1")
    end
  end

  describe '/journey' do
    valid_method = "POST"

    def request_perform_journey(body, content_type: "application/json", method: "POST")
      custom_request(method, '/journey', body, "CONTENT_TYPE" => content_type)
    end

    it "responds 200 for #{valid_method} requests when registered correctly" do
      group = {
        id: 1,
        people: 4
      }
      request_perform_journey(group.to_json)

      expect(service).to have_received(:add_group_journey)
        .with(1, 4)

      expect(last_response.status).to eq(200)
    end

    (ALL_METHODS - [valid_method]).each do |invalid_method|
      it "responds 405 for #{invalid_method} requests" do
        group = {
          id: 1,
          people: 4
        }
        request_perform_journey(group.to_json, method: invalid_method)

        expect(last_response.status).to eq(405)
      end
    end

    it 'responds 400 for invalid content type' do
      group = {
        id: 1,
        people: 4
      }
      request_perform_journey(group.to_json, content_type: "::invalid_content_type::")

      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq("expected content type to be json")
    end

    it 'responds 400 for invalid json' do
      request_perform_journey('::invalid::')

      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq("invalid json\nunexpected token at '::invalid::'")
    end

    it 'responds 400 for other types' do
      request_perform_journey([].to_json)

      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq("expected an object")
    end

    it 'responds 400 for missing id' do
      group = {
        people: 4
      }
      request_perform_journey(group.to_json)

      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq("missing id attribute")
    end

    it 'responds 400 for missing people' do
      group = {
        id: 1
      }
      request_perform_journey(group.to_json)

      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq("missing people attribute")
    end

    it 'responds 400 for non-numeric people' do
      group = {
        id: 1,
        people: 5.3
      }
      request_perform_journey(group.to_json)

      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq("expected people to be an integer")
    end

    it 'responds 409 for duplicate ids' do
      group = {
        id: 1,
        people: 4
      }
      allow(service).to receive(:add_group_journey)
        .and_raise(CarPooling::DuplicateIdError.new(id: 1))

      request_perform_journey(group.to_json)

      expect(last_response.status).to eq(409)
      expect(last_response.body).to eq("duplicate id: 1")
    end
  end

  describe '/dropoff' do
    valid_method = "POST"

    def request_dropoff(body, content_type: "application/x-www-form-urlencoded", method: "POST")
      custom_request(method, '/dropoff', body, "CONTENT_TYPE" => content_type)
    end

    it "responds 200 for #{valid_method} requests when unregistered correctly" do
      id = 1
      request_dropoff("ID=#{id}")

      expect(service).to have_received(:dropoff_group_by_id)
        .with(id)

      expect(last_response.status).to eq(200)
    end

    (ALL_METHODS - [valid_method]).each do |invalid_method|
      it "responds 405 for #{invalid_method} requests" do
        request_dropoff("ID=1", method: invalid_method)

        expect(last_response.status).to eq(405)
      end
    end

    it 'responds 400 for invalid content type' do
      request_dropoff("ID=1", content_type: "::invalid_content_type::")

      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq("expected content type to be form urlencoded")
    end

    it 'responds 400 when not only one id' do
      ['', 'ID=1&ID=2'].each do |body|
        request_dropoff(body)

        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq("expected one ID x-www-form-urlencoded parameter")
      end
    end

    it 'responds 404 when not found' do
      id = 1
      allow(service).to receive(:dropoff_group_by_id)
        .with(id)
        .and_raise(CarPooling::MissingIdError.new(id: id))

      request_dropoff("ID=#{id}")

      expect(last_response.status).to eq(404)
    end
  end

  describe '/locate' do
    valid_method = "POST"

    def request_locate(body, content_type: "application/x-www-form-urlencoded", method: "POST")
      custom_request(method, '/locate', body, "CONTENT_TYPE" => content_type)
    end

    it "responds 200 for #{valid_method} requests with the car" do
      id = "1"

      car = [2, 4]
      allow(service).to receive(:locate_car_by_group_id)
        .with(id.to_i)
        .and_return(car)

      request_locate("ID=#{id}")

      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq({id: 2, seats: 4}.to_json)
    end

    (ALL_METHODS - [valid_method]).each do |invalid_method|
      it "responds 405 for #{invalid_method} requests" do
        request_locate("ID=1", method: invalid_method)

        expect(last_response.status).to eq(405)
      end
    end

    it 'responds 400 for invalid content type' do
      request_locate("ID=1", content_type: "::invalid_content_type::")

      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq("expected content type to be form urlencoded")
    end

    it 'responds 400 when not only one id' do
      ['', 'ID=1&ID=2'].each do |body|
        request_locate(body)

        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq("expected one ID x-www-form-urlencoded parameter")
      end
    end

    it 'responds 404 when the group is not found' do
      id = 1

      allow(service).to receive(:locate_car_by_group_id)
        .with(id)
        .and_raise(CarPooling::MissingIdError.new(id: id))

      request_locate("ID=#{id}")

      expect(last_response.status).to eq(404)
    end

    it 'responds 204 when no assigned car' do
      id = 1

      allow(service).to receive(:locate_car_by_group_id)
        .with(id)
        .and_return(nil)

      request_locate("ID=#{id}")

      expect(last_response.status).to eq(204)
    end
  end
end
