require 'car_pooling/service'

module CarPooling
  RSpec.describe Service do
    describe 'non-existent ids raise MissingIdError' do
      it 'locating a non-existent group' do
        service = described_class.new([])

        expect{
          service.locate_car_by_group_id(1)
        }.to raise_error(MissingIdError)
      end

      it 'dropping off a non-existent group' do
        service = described_class.new([])

        expect{
          service.dropoff_group_by_id(1)
        }.to raise_error(MissingIdError)
      end

      it 'dropping off an already dropped off group' do
        car1 = Car.new(id: 1, seats: 4)
        service = described_class.new([car1])

        group1 = Group.new(id: 1, people: 4)
        service.add_group_journey(group1)
        service.dropoff_group_by_id(group1.id)

        expect{
          service.dropoff_group_by_id(group1.id)
        }.to raise_error(MissingIdError)
      end
    end

    describe 'duplicate ids raise DuplicateIdError' do
      it 'setting up the cars' do
        expect{
          described_class.new([
            Car.new(id: 1, seats: 4),
            Car.new(id: 1, seats: 5)
          ])
        }.to raise_error(DuplicateIdError)
      end

      it 'adding a group journey' do
        service = described_class.new([])

        service.add_group_journey(Group.new(id: 1, people: 4))

        expect{
          service.add_group_journey(Group.new(id: 1, people: 5))
        }.to raise_error(DuplicateIdError)
      end

      it 'but can add another group journey with same id after dropped off' do
        car1 = Car.new(id: 1, seats: 4)
        service = described_class.new([car1])

        service.add_group_journey(Group.new(id: 1, people: 4))
        service.dropoff_group_by_id(1)
        service.add_group_journey(Group.new(id: 1, people: 3))

        expect(service.locate_car_by_group_id(1)).to eq(car1)
      end
    end

    describe 'assigns to a car with enough seats immediately when adding a journey' do
      it 'with a group filling the car' do
        car1 = Car.new(id: 1, seats: 1)
        service = described_class.new([car1])

        group1 = Group.new(id: 1, people: 1)
        service.add_group_journey(group1)
        expect(service.locate_car_by_group_id(group1.id)).to eq(car1)
      end

      it 'with a group leaving a seat in the car' do
        car1 = Car.new(id: 1, seats: 2)
        service = described_class.new([car1])

        group1 = Group.new(id: 1, people: 1)
        service.add_group_journey(group1)
        expect(service.locate_car_by_group_id(group1.id)).to eq(car1)
      end

      it 'allowing two groups on the same car' do
        car1 = Car.new(id: 1, seats: 2)
        service = described_class.new([car1])

        group1 = Group.new(id: 1, people: 1)
        service.add_group_journey(group1)
        expect(service.locate_car_by_group_id(group1.id)).to eq(car1)

        group2 = Group.new(id: 2, people: 1)
        service.add_group_journey(group2)
        expect(service.locate_car_by_group_id(group2.id)).to eq(car1)

        service.dropoff_group_by_id(group1.id)
        expect(service.locate_car_by_group_id(group2.id)).to eq(car1)
      end

      describe 'prefering the car that can be filled the most' do
        it 'a car would be completely filled' do
          car1 = Car.new(id: 1, seats: 6)
          car2 = Car.new(id: 2, seats: 5)
          car3 = Car.new(id: 3, seats: 6)
          service = described_class.new([car1, car2, car3])

          group1 = Group.new(id: 1, people: 5)
          service.add_group_journey(group1)
          expect(service.locate_car_by_group_id(group1.id)).to eq(car2)
        end

        it 'a car with a group would be completely filled' do
          car1 = Car.new(id: 1, seats: 3)
          car2 = Car.new(id: 2, seats: 6)
          service = described_class.new([car1, car2])

          group1 = Group.new(id: 1, people: 4)
          service.add_group_journey(group1)
          expect(service.locate_car_by_group_id(group1.id)).to eq(car2)

          group2 = Group.new(id: 2, people: 2)
          service.add_group_journey(group2)
          expect(service.locate_car_by_group_id(group2.id)).to eq(car2)
        end

        it 'two cars would be completely filled' do
          car1 = Car.new(id: 1, seats: 4)
          car2 = Car.new(id: 2, seats: 3)
          car3 = Car.new(id: 3, seats: 3)
          car4 = Car.new(id: 4, seats: 4)
          service = described_class.new([car1, car2, car3, car4])

          group1 = Group.new(id: 1, people: 3)
          service.add_group_journey(group1)
          expect(service.locate_car_by_group_id(group1.id)).to eq(car2).or eq(car3)
        end

        it 'a car with a group and an empty car would be completely filled' do
          car1 = Car.new(id: 1, seats: 3)
          car2 = Car.new(id: 2, seats: 7)
          service = described_class.new([car1, car2])

          group1 = Group.new(id: 1, people: 4)
          service.add_group_journey(group1)
          expect(service.locate_car_by_group_id(group1.id)).to eq(car2)

          group2 = Group.new(id: 2, people: 3)
          service.add_group_journey(group2)
          expect(service.locate_car_by_group_id(group2.id)).to eq(car1).or eq(car2)
        end

        it 'one car would be almost filled' do
          car1 = Car.new(id: 1, seats: 4)
          car2 = Car.new(id: 2, seats: 3)
          car3 = Car.new(id: 3, seats: 4)
          service = described_class.new([car1, car2, car3])

          group1 = Group.new(id: 1, people: 2)
          service.add_group_journey(group1)
          expect(service.locate_car_by_group_id(group1.id)).to eq(car2)
        end

        it 'two cars would be almost filled' do
          car1 = Car.new(id: 1, seats: 3)
          car2 = Car.new(id: 2, seats: 3)
          service = described_class.new([car1, car2])

          group1 = Group.new(id: 1, people: 2)
          service.add_group_journey(group1)
          expect(service.locate_car_by_group_id(group1.id)).to eq(car1).or eq(car2)
        end
      end
    end

    describe 'groups wait to be assigned' do
      it 'for forever when no cars' do
        service = described_class.new([])

        group1 = Group.new(id: 1, people: 1)
        service.add_group_journey(group1)
        expect(service.locate_car_by_group_id(group1.id)).to eq(nil)
      end

      it 'for forever when there is no car with enough seats' do
        car1 = Car.new(id: 1, seats: 1)
        service = described_class.new([car1])

        group1 = Group.new(id: 1, people: 2)
        service.add_group_journey(group1)
        expect(service.locate_car_by_group_id(group1.id)).to eq(nil)
      end

      it 'queuing in order until a car becomes available' do
        car1 = Car.new(id: 1, seats: 1)
        service = described_class.new([car1])

        group1 = Group.new(id: 1, people: 1)
        service.add_group_journey(group1)
        expect(service.locate_car_by_group_id(group1.id)).to eq(car1)

        group2 = Group.new(id: 2, people: 1)
        service.add_group_journey(group2)
        expect(service.locate_car_by_group_id(group2.id)).to eq(nil)

        group3 = Group.new(id: 3, people: 1)
        service.add_group_journey(group3)
        expect(service.locate_car_by_group_id(group3.id)).to eq(nil)

        service.dropoff_group_by_id(group1.id)
        expect(service.locate_car_by_group_id(group2.id)).to eq(car1)
        expect(service.locate_car_by_group_id(group3.id)).to eq(nil)
      end

      it 'being skipped from the queue if not enough seats are released' do
        car1 = Car.new(id: 1, seats: 2)
        service = described_class.new([car1])

        group1 = Group.new(id: 1, people: 1)
        service.add_group_journey(group1)
        expect(service.locate_car_by_group_id(group1.id)).to eq(car1)

        group2 = Group.new(id: 2, people: 2)
        service.add_group_journey(group2)
        expect(service.locate_car_by_group_id(group2.id)).to eq(nil)

        group3 = Group.new(id: 3, people: 1)
        service.add_group_journey(group3)
        expect(service.locate_car_by_group_id(group3.id)).to eq(car1)

        service.dropoff_group_by_id(group1.id)
        expect(service.locate_car_by_group_id(group2.id)).to eq(nil)
        expect(service.locate_car_by_group_id(group3.id)).to eq(car1)

        service.dropoff_group_by_id(group3.id)
        expect(service.locate_car_by_group_id(group2.id)).to eq(car1)
      end

      it 'to the same car at once if many groups fit' do
        car1 = Car.new(id: 1, seats: 2)
        service = described_class.new([car1])

        group1 = Group.new(id: 1, people: 2)
        service.add_group_journey(group1)
        expect(service.locate_car_by_group_id(group1.id)).to eq(car1)

        group2 = Group.new(id: 2, people: 1)
        service.add_group_journey(group2)
        group3 = Group.new(id: 3, people: 1)
        service.add_group_journey(group3)

        expect(service.locate_car_by_group_id(group2.id)).to eq(nil)
        expect(service.locate_car_by_group_id(group3.id)).to eq(nil)

        service.dropoff_group_by_id(group1.id)
        expect(service.locate_car_by_group_id(group2.id)).to eq(car1)
        expect(service.locate_car_by_group_id(group3.id)).to eq(car1)
      end
    end
  end
end
