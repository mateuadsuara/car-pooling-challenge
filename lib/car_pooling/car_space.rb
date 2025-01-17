require 'set'

module CarPooling
  class CarSpace
    def initialize(car_seats)
      @car_space = car_seats.clone
      @space_on_cars = {}
      @car_space.each do |id, space|
        set_space_on_car(id, space)
      end
      @group_car = {}
    end

    def add_group(id, people, car_id = nil)
      if car_id
        previous_space = @car_space[car_id]
      else
        car_id, previous_space = car_with_closest_available_space_for_group_of(people)
        return nil unless car_id
      end

      next_space = previous_space - people
      @car_space[car_id] = next_space
      change_space_on_car(car_id, previous_space, next_space)

      @group_car[id] = car_id
      car_id
    end

    def remove_group(id, people)
      car_id = car_for_group(id)
      previous_space = @car_space[car_id]
      return nil unless car_id

      next_space = previous_space + people
      @car_space[car_id] = next_space
      change_space_on_car(car_id, previous_space, next_space)

      @group_car.delete(id)
      car_id
    end

    def car_for_group(id)
      @group_car[id]
    end

    def available_space_for_car(id)
      @car_space[id]
    end

    def to_h
      @car_space
    end

    private

    def car_with_closest_available_space_for_group_of(people)
      closest_available_space = @space_on_cars.keys.sort.find do |space|
        space >= people
      end
      return nil unless closest_available_space
      @space_on_cars[closest_available_space].each do |car_id|
        return [car_id, closest_available_space]
      end
    end

    def set_space_on_car(car_id, space)
      @space_on_cars[space] ||= Set.new
      @space_on_cars[space].add(car_id)
    end

    def unset_space_on_car(car_id, space)
      @space_on_cars[space].delete(car_id)
      @space_on_cars.delete(space) if @space_on_cars[space].empty?
    end

    def change_space_on_car(car_id, previous, current)
      unset_space_on_car(car_id, previous)
      set_space_on_car(car_id, current)
    end
  end
end
