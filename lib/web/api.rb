require 'rack'
require 'json'
require 'cgi'

module Web
  class Api
    include Rack

    def initialize(service_class)
      @service_class = service_class
      @service = @service_class.new({})
    end

    def call(environment)
      request = Request.new(environment)
      response = handle(request)
      response.finish
    end

    def handle(request)
      [
        :handle_status,
        :handle_cars,
        :handle_journey,
        :handle_dropoff,
        :handle_locate
      ].each do |endpoint|
        maybe_response = send(endpoint, request)
        return maybe_response if maybe_response
      end

      Response.new(nil, 404)
    end

    def handle_status(request)
      return nil unless request.path_info == "/status"
      return Response.new("", 405) unless request.get?

      Response.new("ready", 200)
    end

    def handle_cars(request)
      return nil unless request.path_info == "/cars"
      return Response.new("", 405) unless request.put?

      begin
        cars = Parser.parse_car_list(request)
      rescue => e
        return Response.new(e.message, 400)
      end

      @service = @service_class.new(cars)

      Response.new("", 200)
    end

    def handle_journey(request)
      return nil unless request.path_info == "/journey"
      return Response.new("", 405) unless request.post?

      begin
        group = Parser.parse_group(request)
      rescue => e
        return Response.new(e.message, 400)
      end

      begin
        @service.add_group_journey(group.id, group.people)
      rescue CarPooling::DuplicateIdError => e
        return Response.new("duplicate id: #{e.id}", 409)
      end

      Response.new("", 200)
    end

    def handle_dropoff(request)
      return nil unless request.path_info == "/dropoff"
      return Response.new("", 405) unless request.post?

      begin
        id = Parser.parse_id(request)
      rescue => e
        return Response.new(e.message, 400)
      end

      begin
        @service.dropoff_group_by_id(id)
      rescue CarPooling::MissingIdError
        return Response.new("", 404)
      end

      Response.new("", 200)
    end

    def handle_locate(request)
      return nil unless request.path_info == "/locate"
      return Response.new("", 405) unless request.post?

      begin
        id = Parser.parse_id(request)
      rescue => e
        return Response.new(e.message, 400)
      end

      begin
        car_id, car_seats = @service.locate_car_by_group_id(id)
      rescue CarPooling::MissingIdError
        return Response.new("", 404)
      end

      return Response.new("", 204) unless car_id

      Response.new({id: car_id, seats: car_seats}.to_json, 200)
    end
  end

  class Parser
    Car = Struct.new(:id, :seats, keyword_init: true)

    Group = Struct.new(:id, :people, keyword_init: true)

    def self.parse_json(request)
      if (request.content_type&.downcase != "application/json")
        raise StandardError.new("expected content type to be json")
      end

      body = request.body.gets

      begin
        return JSON.parse(body)
      rescue => e
        raise StandardError.new("invalid json\n#{e.message}")
      end
    end

    def self.parse_car_list(request)
      json = self.parse_json(request)

      raise StandardError.new("expected a list") unless json.kind_of?(Array)

      idx = 0
      cars = {}
      json.each do |c|
        idx += 1
        car = self.parse_car_element(c, idx -1)
        raise StandardError.new("duplicate id: #{car.id}") if cars.has_key?(car.id)
        cars[car.id] = car.seats
      end

      cars
    end

    def self.parse_car_element(c, idx)
      raise StandardError.new("expected the element on index #{idx} to be an object") unless c.kind_of?(Hash)

      id, seats = c.values_at("id", "seats")
      raise StandardError.new("missing id attribute on index #{idx}") unless id
      raise StandardError.new("missing seats attribute on index #{idx}") unless seats

      Car.new(c)
    end

    def self.parse_group(request)
      json = self.parse_json(request)
      raise StandardError.new("expected an object") unless json.kind_of?(Hash)

      id, people = json.values_at("id", "people")
      raise StandardError.new("missing id attribute") unless id
      raise StandardError.new("missing people attribute") unless people

      Group.new(json)
    end

    def self.parse_id(request)
      if (request.content_type&.downcase != "application/x-www-form-urlencoded")
        raise StandardError.new("expected content type to be form urlencoded")
      end

      body = request.body.gets

      begin
        params = CGI::parse(body)
        ids = params["ID"]
      rescue
      end

      raise StandardError.new("expected one ID x-www-form-urlencoded parameter") unless ids&.length == 1

      begin
        id = Integer(ids.first)
      rescue
        raise StandardError.new("expected ID to be an integer")
      end

      id
    end
  end
end
