require 'car_pooling/car_space'
require 'car_pooling/waiting_queue'
require 'set'

module CarPooling
  class ErrorWithId < StandardError
    attr_reader :id

    def initialize(id:)
      @id = id
    end
  end

  class MissingIdError < ErrorWithId; end
  class DuplicateIdError < ErrorWithId; end

  class Service
    def initialize(car_seats)
      @car_seats = car_seats
      @group_people = {}
      @car_space = CarSpace.new(@car_seats)
      @queue = WaitingQueue.new
    end

    def add_group_journey(id, people)
      raise DuplicateIdError.new(id: id) if @group_people[id]

      @group_people[id] = people
      assigned_car_id = @car_space.add_group(id, people)

      @queue.enqueue(id, people) unless assigned_car_id
      nil
    end

    def dropoff_group_by_id(group_id)
      group_people = @group_people[group_id]
      raise MissingIdError.new(id: group_id) unless group_people

      freed_car_id = @car_space.remove_group(group_id, group_people)
      @group_people.delete(group_id)

      if !freed_car_id
        @queue.remove(group_id)
        return
      end

      loop do
        available_space = @car_space.available_space_for_car(freed_car_id)
        next_group_id, next_people = @queue.next_fitting_in(available_space)
        break unless next_group_id
        @car_space.add_group(next_group_id, next_people, freed_car_id)
        @queue.remove(next_group_id)
      end

      nil
    end

    def locate_car_by_group_id(group_id)
      raise MissingIdError.new(id: group_id) unless @group_people[group_id]

      car_id = @car_space.car_for_group(group_id)
      [car_id, @car_seats[car_id]] if car_id
    end
  end
end
