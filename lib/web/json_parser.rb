require 'json'

module Web
  class JSONParser
    def self.parse_car_list(request)
      json = self.parse_json(request)

      raise StandardError.new("expected a list") unless json.kind_of?(Array)

      cars = {}
      idx = 0
      json.each do |c|
        car = self.parse_car_element(c, idx)
        raise StandardError.new("duplicate id: #{car.id}") if cars.has_key?(car.id)
        cars[car.id] = car.seats
        idx += 1
      end

      cars
    end

    Car = Struct.new(:id, :seats, keyword_init: true)
    def self.parse_car_element(c, idx)
      raise StandardError.new("expected the element on index #{idx} to be an object") unless c.kind_of?(Hash)

      id, seats = c.values_at("id", "seats")
      raise StandardError.new("missing id attribute on index #{idx}") unless id
      raise StandardError.new("missing seats attribute on index #{idx}") unless seats

      Car.new(c)
    end

    Group = Struct.new(:id, :people, keyword_init: true)
    def self.parse_group(request)
      json = self.parse_json(request)
      raise StandardError.new("expected an object") unless json.kind_of?(Hash)

      id, people = json.values_at("id", "people")
      raise StandardError.new("missing id attribute") unless id
      raise StandardError.new("missing people attribute") unless people

      Group.new(json)
    end

    def self.parse_json(request)
      if (request.content_type&.downcase != "application/json")
        raise StandardError.new("expected content type to be json")
      end

      body = request.body

      begin
        return JSON.load(body)
      rescue => e
        raise StandardError.new("invalid json\n#{e.message}")
      end
    end
  end
end
