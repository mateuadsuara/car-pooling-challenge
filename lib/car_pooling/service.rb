require 'car_space'
require 'keyed_queue'
require 'set'

module CarPooling
  class MissingIdError < StandardError
    attr_reader :id

    def initialize(id:)
      @id = id
    end
  end

  class DuplicateIdError < StandardError
    attr_reader :id

    def initialize(id:)
      @id = id
    end
  end

  Car = Struct.new(:id, :seats, keyword_init: true)

  Group = Struct.new(:id, :people, keyword_init: true)

  class Service
    def initialize(cars)
      ids = Set.new
      car_with_duplicate_id = cars.find{|c| !ids.add?(c.id)}
      raise DuplicateIdError.new(id: car_with_duplicate_id.id) if car_with_duplicate_id

      @car_seats = cars.inject({}){|acc, car| acc[car.id] = car.seats; acc}
      @group_people = {}
      @car_space = CarSpace.new(@car_seats)
      @queue = KeyedQueue.new
    end

    def add_group_journey(group)
      raise DuplicateIdError.new(id: group.id) if @group_people[group.id]

      @group_people[group.id] = group.people
      assigned_car_id = @car_space.add_group(group.id, group.people)

      @queue.push(group.id) unless assigned_car_id
      nil
    end

    def dropoff_group_by_id(group_id)
      raise MissingIdError.new(id: group_id) unless @group_people[group_id]

      freed_car_id = @car_space.remove_group(group_id, @group_people[group_id])
      @group_people.delete(group_id)

      if freed_car_id
        @queue.each do |next_waiting_group_id|
          assigned_car = @car_space.add_group(next_waiting_group_id, @group_people[next_waiting_group_id])
          #@queue.remove(next_waiting_group_id) if assigned_car #TODO: test

          break if @car_space.space_for_car(freed_car_id) == 0
        end
      else
        @queue.remove(group_id)
      end
      nil
    end

    def locate_car_by_group_id(group_id)
      raise MissingIdError.new(id: group_id) unless @group_people[group_id]

      car_id = @car_space.car_for_group(group_id)
      Car.new(id: car_id, seats: @car_seats[car_id]) if car_id
    end
  end
end
