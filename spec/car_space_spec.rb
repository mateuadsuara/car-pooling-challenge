require 'rspec'
require 'car_space'

RSpec.describe CarSpace do
  it 'no cars' do
    s = described_class.new({})

    assigned_car_id = s.add_group(1, 4)

    expect(assigned_car_id).to eq(nil)
    expect(s.car_for_group(1)).to eq(nil)
    expect(s.space_for_car(1)).to eq(nil)
    expect(s.to_h).to eq({})
  end

  it 'a group does not fit' do
    s = described_class.new({1 => 4})

    assigned_car_id = s.add_group(2, 5)

    expect(assigned_car_id).to eq(nil)
    expect(s.car_for_group(2)).to eq(nil)
    expect(s.space_for_car(1)).to eq(4)
    expect(s.to_h).to eq({1 => 4})
  end

  it 'filling a car' do
    car_id = 1
    car_seats = {car_id => 4}
    s = described_class.new(car_seats)

    group_id = 2
    assigned_car_id = s.add_group(group_id, 4)

    expect(assigned_car_id).to eq(car_id)
    expect(s.car_for_group(group_id)).to eq(car_id)
    expect(s.space_for_car(car_id)).to eq(0)
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
    puts s.inspect
  end

  xit 'prefering the car that can be filled the most'
end
