require 'rspec'
require 'benchmark'
require 'benchmark/memory'
require 'ruby-prof'

require 'car_pooling/service'

RSpec.describe CarPooling::Service, performance: true do
  def random_cars(n)
    cars = {}
    (1..n).each do |i|
      id = i
      seats = rand(3) + 4
      #seats = (i % 3) + 4
      cars[id] = seats
    end
    cars
  end

  def random_group
    id = rand(1_000_000) + 1_000_000
    people = rand(6) + 1
    {id: id, people: people}
  end

  def random_groups(n)
    (1..n).map do |i|
      id = i
      people = rand(6) + 1
      #people = (i % 6) + 1
      {id: id, people: people}
    end
  end

  def setup(cars, groups)
    s = described_class.new(cars)
    groups.each do |g|
      s.add_group_journey(g[:id], g[:people])
    end
    s
  end

  def measure_times(cars_n, groups_n)
    gs = random_groups(groups_n)
    cs = random_cars(cars_n)
    s = setup(cs, gs)

    puts ""
    puts "="*40
    puts "time measurements for #{cars_n} cars, #{groups_n} groups"
    puts "="*40
    Benchmark.bmbm { |x|
      x.report("load cars"){
        described_class.new(cs)
      }
      x.report("add journey"){
        g = random_group
        s.add_group_journey(g[:id], g[:people])
      }
      x.report("dropoff group"){
        s.dropoff_group_by_id(gs.sample[:id])
      }
      x.report("locate group car"){
        s.locate_car_by_group_id(gs.sample[:id])
      }
    }
  end

  it 'time measurements' do
    measure_times(1_000, 1_000)
    measure_times(10_000, 10_000)
    measure_times(100_000, 100_000)
    measure_times(1_000_000, 1_000_000)
  end

  def measure_memory(cars_n, groups_n)
    gs = random_groups(groups_n)
    cs = random_cars(cars_n)

    puts ""
    puts "="*40
    puts "memory measurements for #{cars_n} cars, #{groups_n} groups"
    puts "="*40
    Benchmark.memory do |x|
      x.report("loaded cars and groups"){
        s = described_class.new(cs)
        gs.each do |g|
          s.add_group_journey(g[:id], g[:people])
        end
      }
    end
  end

  it 'memory measurements' do
    measure_memory(0, 0)
    measure_memory(0, 1_000)
    measure_memory(0, 10_000)
    measure_memory(0, 100_000)
    measure_memory(0, 1_000_000)

    measure_memory(0, 0)
    measure_memory(1_000, 0)
    measure_memory(10_000, 0)
    measure_memory(100_000, 0)
    measure_memory(1_000_000, 0)

    measure_memory(0, 0)
    measure_memory(1_000, 1_000)
    measure_memory(10_000, 10_000)
    measure_memory(100_000, 100_000)
    measure_memory(1_000_000, 1_000_000)
  end

  it 'profile' do
    n = 100_000
    cars = random_cars(n)
    groups = random_groups(n)

    profile = RubyProf::Profile.new
    profile.exclude_common_methods!
    profile.start

    gs = random_groups(n)
    cs = random_cars(n)
    s = setup(cs, gs)
    gs.each do |g|
      s.locate_car_by_group_id(g[:id])
      s.dropoff_group_by_id(g[:id])
    end

    result = profile.stop

    printer = RubyProf::FlatPrinter.new(result)
    printer.print(STDOUT)
  end
end
