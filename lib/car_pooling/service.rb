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

  class CarToGroups
    attr_accessor :car, :to_groups

    def initialize(car)
      @car = car
      @to_groups = []
    end

    def available_seats
      @car.seats - @to_groups.map{|tg| tg.group.people}.sum
    end

    def can_fit?(group)
      available_seats >= group.people
    end

    def remove_group(group_id)
      to_groups.reject!{|tg| tg.group.id == group_id}
    end
  end

  Group = Struct.new(:id, :people, keyword_init: true)

  class GroupToCar
    attr_accessor :group, :to_car

    def initialize(group)
      @group = group
      @to_car = nil
    end
  end

  class Service
    def initialize(cars)
      duplicate_car_id, _ = cars.group_by{|c| c.id}.find{|id, cars_per_id| cars_per_id.length > 1 }
      raise DuplicateIdError.new(id: duplicate_car_id) if duplicate_car_id

      @many_car_to_groups = cars.map{|c| CarToGroups.new(c)}
      @many_group_to_car = []
    end

    def add_group_journey(group)
      previous_journey_with_same_id = @many_group_to_car.find{|gtc| gtc.group.id == group.id}
      raise DuplicateIdError.new(id: group.id) if previous_journey_with_same_id

      group_to_car = GroupToCar.new(group)

      best_available_car = @many_car_to_groups
        .sort_by{|ctg| ctg.available_seats}
        .find{|ctg| ctg.can_fit?(group)}
      if best_available_car
        set_relationship(best_available_car, group_to_car)
      end

      @many_group_to_car << group_to_car
    end

    def dropoff_group_by_id(group_id)
      group_index = @many_group_to_car.find_index{|gtc| gtc.group.id == group_id}
      raise MissingIdError.new(id: group_id) unless group_index

      dropped_off_group = @many_group_to_car[group_index]
      @many_group_to_car[group_index] = nil
      @many_group_to_car.compact!

      freed_car = dropped_off_group.to_car
      freed_car.remove_group(group_id)

      @many_group_to_car.filter{|gtc| gtc.to_car.nil?}.each do |next_waiting_group|
        if freed_car.can_fit?(next_waiting_group.group)
          set_relationship(freed_car, next_waiting_group)
        end

        break if freed_car.available_seats == 0
      end
    end

    def locate_car_by_group_id(group_id)
      located_group = @many_group_to_car.find{|gtc| gtc.group.id == group_id}
      raise MissingIdError.new(id: group_id) unless located_group

      located_group.to_car&.car
    end

    private

    def set_relationship(car, group)
      car.to_groups << group
      group.to_car = car
    end
  end
end
