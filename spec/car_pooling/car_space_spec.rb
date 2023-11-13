require 'rspec'
require 'car_pooling/car_space'

RSpec.describe CarPooling::CarSpace do
  it 'no cars' do
    s = described_class.new({})

    assigned_car_id = s.add_group(1, 4)

    expect(assigned_car_id).to eq(nil)
    expect(s.car_for_group(1)).to eq(nil)
    expect(s.available_space_for_car(1)).to eq(nil)
    expect(s.to_h).to eq({})
  end

  it 'a group does not fit' do
    s = described_class.new({1 => 4})

    assigned_car_id = s.add_group(2, 5)

    expect(assigned_car_id).to eq(nil)
    expect(s.car_for_group(2)).to eq(nil)
    expect(s.available_space_for_car(1)).to eq(4)
    expect(s.to_h).to eq({1 => 4})
  end

  it 'a group can be added to a specific car' do
    car_id = 1
    s = described_class.new({car_id => 4})

    group_id = 2
    assigned_car_id = s.add_group(group_id, 5, car_id)

    expect(assigned_car_id).to eq(car_id)
    expect(s.car_for_group(group_id)).to eq(car_id)
    expect(s.available_space_for_car(car_id)).to eq(-1)
    expect(s.to_h).to eq({car_id => -1})
  end

  it 'filling a car' do
    car_id = 1
    car_seats = {car_id => 4}
    s = described_class.new(car_seats)

    group_id = 2
    assigned_car_id = s.add_group(group_id, 4)

    expect(assigned_car_id).to eq(car_id)
    expect(s.car_for_group(group_id)).to eq(car_id)
    expect(s.available_space_for_car(car_id)).to eq(0)
    expect(s.to_h).to eq({car_id => 0})
    expect(car_seats).to eq({car_id => 4})
  end

  it 'remove a group' do
    car_id = 1
    s = described_class.new({car_id => 4})

    group_id = 2
    s.add_group(group_id, 3)
    removed_car_id = s.remove_group(group_id, 3)

    expect(removed_car_id).to eq(car_id)
    expect(s.car_for_group(group_id)).to eq(nil)
    expect(s.to_h).to eq({car_id => 4})
  end

  it 'remove a non added group' do
    s = described_class.new({1 => 4})

    group_id = 2
    removed_car_id = s.remove_group(group_id, 3)
    expect(removed_car_id).to eq(nil)
    expect(s.car_for_group(group_id)).to eq(nil)
    expect(s.to_h).to eq({1 => 4})
  end

  it 'multiple groups on the same car' do
    car_id = 10
    s = described_class.new({car_id => 6})

    expect(s.add_group(2, 1)).to eq(car_id)
    expect(s.car_for_group(2)).to eq(car_id)
    expect(s.to_h).to eq({car_id => 5})

    expect(s.add_group(3, 2)).to eq(car_id)
    expect(s.car_for_group(3)).to eq(car_id)
    expect(s.to_h).to eq({car_id => 3})

    expect(s.remove_group(2, 1)).to eq(car_id)
    expect(s.car_for_group(2)).to eq(nil)
    expect(s.to_h).to eq({car_id => 4})
  end

  describe 'prefering the car that can be filled the most' do
    it 'a car would be completely filled' do
      car_id = 2
      s = described_class.new({
        1 => 6,
        car_id => 5,
        3 => 6
      })

      expect(s.add_group(1, 5)).to eq(car_id)
      expect(s.car_for_group(1)).to eq(car_id)
      expect(s.to_h).to eq({
        1 => 6,
        car_id => 0,
        3 => 6
      })
    end

    it 'a car with a group would be completely filled' do
      car_id = 2
      s = described_class.new({
        1 => 3,
        car_id => 6
      })

      s.add_group(1, 4)

      expect(s.add_group(2, 2)).to eq(car_id)
      expect(s.car_for_group(2)).to eq(car_id)
      expect(s.to_h).to eq({
        1 => 3,
        car_id => 0
      })
    end

    it 'two cars would be completely filled' do
      car_a = 2
      car_b = 3
      s = described_class.new({
        1 => 4,
        car_a => 3,
        car_b => 3,
        4 => 4
      })

      car_id = s.add_group(1, 3)
      expect(car_id).to eq(car_a).or eq(car_b)
      expect(s.car_for_group(1)).to eq(car_id)
      expect(s.to_h).to eq({
        1 => 4,
        car_a => 0,
        car_b => 3,
        4 => 4
      }).or eq({
        1 => 4,
        car_a => 3,
        car_b => 0,
        4 => 4
      })
    end

    it 'a car with a group and an empty car would be completely filled' do
      car_a = 2
      car_b = 3
      s = described_class.new({
        1 => 2,
        car_a => 3,
        car_b => 7,
        4 => 2
      })

      s.add_group(1, 4)

      car_id = s.add_group(2, 3)
      expect(car_id).to eq(car_a).or eq(car_b)
      expect(s.car_for_group(2)).to eq(car_id)
      expect(s.to_h).to eq({
        1 => 2,
        car_a => 0,
        car_b => 3,
        4 => 2
      }).or eq({
        1 => 2,
        car_a => 3,
        car_b => 0,
        4 => 2
      })
    end

    it 'one car would be almost filled' do
      car_id = 2
      s = described_class.new({
        1 => 4,
        car_id => 3,
        3 => 4
      })

      expect(s.add_group(1, 2)).to eq(car_id)
      expect(s.car_for_group(1)).to eq(car_id)
      expect(s.to_h).to eq({
        1 => 4,
        car_id => 1,
        3 => 4
      })
    end

    it 'two cars would be almost filled' do
      car_a = 2
      car_b = 3
      s = described_class.new({
        1 => 4,
        car_a => 3,
        car_b => 3,
        4 => 4
      })

      car_id = s.add_group(1, 2)
      expect(car_id).to eq(car_a).or eq(car_b)
      expect(s.car_for_group(1)).to eq(car_id)
      expect(s.to_h).to eq({
        1 => 4,
        car_a => 1,
        car_b => 3,
        4 => 4
      }).or eq({
        1 => 4,
        car_a => 3,
        car_b => 1,
        4 => 4
      })
    end
  end
end
