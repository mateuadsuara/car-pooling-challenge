require 'set'

class CarSpace
  def initialize(car_seats)
    @car_space = car_seats.clone
    @space_on_cars = {}
    @car_space.each do |id, space|
      set_space_on_car(id, space)
    end
    @group_car = {}
  end

  def add_group(id, people)
    car_id, closest_available_space = best_car_for_group_of(people)
    return nil unless car_id

    @group_car[id] = car_id
    @car_space[car_id] -= people
    unset_space_on_car(car_id, closest_available_space)
    set_space_on_car(car_id, @car_space[car_id])
    car_id
  end

  def remove_group(id, people)
    car_id = car_for_group(id)
    return nil unless car_id

    previous_space = @car_space[car_id]
    @car_space[car_id] += people
    unset_space_on_car(car_id, previous_space)
    set_space_on_car(car_id, @car_space[car_id])

    @group_car.delete(id)
    car_id
  end

  def car_for_group(id)
    @group_car[id]
  end

  def space_for_car(id)
    @car_space[id]
  end

  def to_h
    @car_space
  end

  private

  def best_car_for_group_of(people)
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
end
