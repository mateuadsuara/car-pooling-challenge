require 'car_pooling/service'

module CarPooling
  RSpec.describe Service do
    def new_service(car_list)
      car_seats = car_list.reduce({}){|acc, c| acc[c.id]=c.seats; acc}
      described_class.new(car_seats)
    end

    describe 'non-existent ids raise MissingIdError' do
      it 'locating a non-existent group' do
        service = described_class.new({})

        expect{
          service.locate_car_by_group_id(1)
        }.to raise_error(MissingIdError)
      end

      it 'dropping off a non-existent group' do
        service = described_class.new({})

        expect{
          service.dropoff_group_by_id(1)
        }.to raise_error(MissingIdError)
      end

      it 'dropping off an already dropped off group' do
        service = described_class.new({1=>4})

        group_id = 1
        service.add_group_journey(group_id, 4)
        service.dropoff_group_by_id(group_id)

        expect{
          service.dropoff_group_by_id(group_id)
        }.to raise_error(MissingIdError)
      end
    end

    describe 'duplicate ids raise DuplicateIdError' do
      it 'adding a group journey' do
        service = described_class.new({})

        group_id = 1
        service.add_group_journey(group_id, 4)

        expect{
          service.add_group_journey(group_id, 5)
        }.to raise_error(DuplicateIdError)
      end

      it 'but can add another group journey with same id after dropped off' do
        cars = {1 => 4}
        service = described_class.new(cars)

        group_id = 1
        service.add_group_journey(group_id, 4)
        service.dropoff_group_by_id(group_id)
        service.add_group_journey(group_id, 3)

        expect(service.locate_car_by_group_id(group_id)).to eq(cars.first)
      end
    end

    describe 'assigns to a car with enough seats immediately when adding a journey' do
      it 'with a group filling the car' do
        cars = {1 => 1}
        service = described_class.new(cars)

        group_id = 1
        service.add_group_journey(group_id, 1)
        expect(service.locate_car_by_group_id(group_id)).to eq(cars.first)
      end

      it 'with a group leaving a seat in the car' do
        cars = {1 => 2}
        service = described_class.new(cars)

        group_id = 1
        service.add_group_journey(group_id, 1)
        expect(service.locate_car_by_group_id(group_id)).to eq(cars.first)
      end

      it 'allowing two groups on the same car' do
        cars = {1 => 2}
        service = described_class.new(cars)

        group_id_1 = 1
        service.add_group_journey(group_id_1, 1)
        expect(service.locate_car_by_group_id(group_id_1)).to eq(cars.first)

        group_id_2 = 2
        service.add_group_journey(group_id_2, 1)
        expect(service.locate_car_by_group_id(group_id_2)).to eq(cars.first)

        service.dropoff_group_by_id(group_id_1)
        expect(service.locate_car_by_group_id(group_id_2)).to eq(cars.first)
      end

      describe 'prefering the car that can be filled the most' do
        it 'a car would be completely filled' do
          service = described_class.new({
            1 => 6,
            2 => 5,
            3 => 6
          })

          group_id = 1
          service.add_group_journey(group_id, 5)
          expect(service.locate_car_by_group_id(group_id)).to eq([2, 5])
        end

        it 'a car with a group would be completely filled' do
          service = described_class.new({
            1 => 3,
            2 => 6
          })

          service.add_group_journey(1, 4)
          expect(service.locate_car_by_group_id(1)).to eq([2, 6])

          service.add_group_journey(2, 2)
          expect(service.locate_car_by_group_id(2)).to eq([2, 6])
        end

        it 'two cars would be completely filled' do
          service = described_class.new({
            1 => 4,
            2 => 3,
            3 => 3,
            4 => 4
          })

          group_id = 1
          service.add_group_journey(group_id, 3)
          expect(service.locate_car_by_group_id(group_id)).to eq([2, 3]).or eq([3, 3])
        end

        it 'a car with a group and an empty car would be completely filled' do
          service = described_class.new({
            1 => 2,
            2 => 3,
            3 => 7,
            4 => 2
          })

          service.add_group_journey(1, 4)
          expect(service.locate_car_by_group_id(1)).to eq([3, 7])

          service.add_group_journey(2, 3)
          expect(service.locate_car_by_group_id(2)).to eq([2, 3]).or eq([3, 7])
        end

        it 'one car would be almost filled' do
          service = described_class.new({
            1 => 4,
            2 => 3,
            3 => 4
          })

          group_id = 1
          service.add_group_journey(group_id, 2)
          expect(service.locate_car_by_group_id(group_id)).to eq([2, 3])
        end

        it 'two cars would be almost filled' do
          service = described_class.new({
            1 => 4,
            2 => 3,
            3 => 3,
            4 => 4
          })

          group_id = 1
          service.add_group_journey(group_id, 2)
          expect(service.locate_car_by_group_id(group_id)).to eq([2, 3]).or eq([3, 3])
        end
      end
    end

    describe 'groups wait to be assigned' do
      it 'for forever when no cars' do
        service = described_class.new({})

        group_id = 1
        service.add_group_journey(group_id, 1)
        expect(service.locate_car_by_group_id(group_id)).to eq(nil)
      end

      it 'for forever when there is no car with enough seats' do
        service = described_class.new({1 => 1})

        group_id = 1
        service.add_group_journey(group_id, 2)
        expect(service.locate_car_by_group_id(group_id)).to eq(nil)
      end

      it 'queuing in order until a car becomes available' do
        cars = {1 => 1}
        service = described_class.new(cars)

        service.add_group_journey(1, 1)
        expect(service.locate_car_by_group_id(1)).to eq(cars.first)

        service.add_group_journey(2, 1)
        expect(service.locate_car_by_group_id(2)).to eq(nil)

        service.add_group_journey(3, 1)
        expect(service.locate_car_by_group_id(3)).to eq(nil)

        service.dropoff_group_by_id(1)
        expect(service.locate_car_by_group_id(2)).to eq(cars.first)
        expect(service.locate_car_by_group_id(3)).to eq(nil)
      end

      it 'being skipped from the queue if not enough seats are released' do
        cars = {1 => 2}
        service = described_class.new(cars)

        service.add_group_journey(1, 1)
        expect(service.locate_car_by_group_id(1)).to eq(cars.first)

        service.add_group_journey(2, 2)
        expect(service.locate_car_by_group_id(2)).to eq(nil)

        service.add_group_journey(3, 1)
        expect(service.locate_car_by_group_id(3)).to eq(cars.first)

        service.dropoff_group_by_id(1)
        expect(service.locate_car_by_group_id(2)).to eq(nil)
        expect(service.locate_car_by_group_id(3)).to eq(cars.first)

        service.dropoff_group_by_id(3)
        expect(service.locate_car_by_group_id(2)).to eq(cars.first)
      end

      it 'to the same car at once if many groups fit' do
        cars = {1 => 2}
        service = described_class.new(cars)

        service.add_group_journey(1, 2)
        expect(service.locate_car_by_group_id(1)).to eq(cars.first)

        service.add_group_journey(2, 1)
        service.add_group_journey(3, 1)

        expect(service.locate_car_by_group_id(2)).to eq(nil)
        expect(service.locate_car_by_group_id(3)).to eq(nil)

        service.dropoff_group_by_id(1)
        expect(service.locate_car_by_group_id(2)).to eq(cars.first)
        expect(service.locate_car_by_group_id(3)).to eq(cars.first)
      end

      it 'a long queue' do
        cars = {1 => 5}
        service = described_class.new(cars)

        service.add_group_journey(1, 5)
        expect(service.locate_car_by_group_id(1)).to eq(cars.first)

        queue_size = 10_000
        (2..queue_size).each do |n|
          service.add_group_journey(n, 6)
        end

        last_group_id = queue_size + 1
        service.add_group_journey(last_group_id, 5)

        expect(service.locate_car_by_group_id(1)).to eq(cars.first)
        expect(service.locate_car_by_group_id(last_group_id)).to eq(nil)

        service.dropoff_group_by_id(1)
        expect(service.locate_car_by_group_id(last_group_id)).to eq(cars.first)
      end
    end
  end
end
