require 'rspec'
require 'benchmark'
require 'benchmark/memory'
require 'ruby-prof'

require 'car_pooling/service'

RSpec.describe CarPooling::Service do
  def random_cars(n)
    cars = {}
    (1..n).each do |i|
      id = i
      seats = (i % 3)+4 #rand(3) + 4
      cars[id] = seats
    end
    cars
  end

  def random_group
    id = rand(1_000_000)
    people = rand(6) + 1
    CarPooling::Group.new(id: id, people: people)
  end

  def random_groups(n)
    (1..n).map do |i|
      id = i
      people = (i % 6)+1 #rand(6) + 1
      CarPooling::Group.new(id: id, people: people)
    end
  end

  it '100_000 cars' do
    cars = random_cars(100_000)
    groups = random_groups(100_000)

    Benchmark.bmbm { |x|
      x.report("full"){
        s = described_class.new(cars)
        groups.each do |g|
          s.add_group_journey(g)
          s.locate_car_by_group_id(g.id)
          s.dropoff_group_by_id(g.id)
        end
      }
    }
    Benchmark.memory do |x|
      x.report("full"){
        s = described_class.new(cars)
        groups.each do |g|
          s.add_group_journey(g)
          s.locate_car_by_group_id(g.id)
          s.dropoff_group_by_id(g.id)
        end
      }
    end
  end

  it 'profile' do
    cars = random_cars(100_000)
    groups = random_groups(100_000)

    profile = RubyProf::Profile.new
    profile.exclude_common_methods!
    profile.start

    s = described_class.new(cars)
    groups.each do |g|
      s.add_group_journey(g)
      s.locate_car_by_group_id(g.id)
      s.dropoff_group_by_id(g.id)
    end

    result = profile.stop

    printer = RubyProf::FlatPrinter.new(result)
    printer.print(STDOUT)
  end
end
