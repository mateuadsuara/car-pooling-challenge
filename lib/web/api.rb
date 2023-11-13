require 'rack'

require 'web/json_parser'
require 'web/form_parser'

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
        cars = JSONParser.parse_car_list(request)
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
        group = JSONParser.parse_group(request)
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
        id = FormParser.parse_id(request)
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
        id = FormParser.parse_id(request)
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
end
