require 'rspec'
require 'benchmark'
require 'benchmark/memory'
require 'ruby-prof'

require 'car_pooling/service'

RSpec.describe CarPooling::Service, performance: true do
  def generate_cars(n, seats = nil)
    cars = {}
    (1..n).each do |i|
      id = i
      s = seats || rand(3) + 4
      #s = (i % 3) + 4
      cars[id] = s
    end
    cars
  end

  def random_group
    id = rand(1_000_000) + 1_000_000
    people = rand(6) + 1
    {id: id, people: people}
  end

  def generate_groups(n, people = nil)
    (1..n).map do |i|
      id = i
      p = people || rand(6) + 1
      #p = (i % 6) + 1
      {id: id, people: p}
    end
  end

  def add_groups(service, groups)
    groups.each do |g|
      service.add_group_journey(g[:id], g[:people])
    end
  end

  def setup(cars, groups)
    s = described_class.new(cars)
    add_groups(s, groups)
    s
  end

  def print_desc(desc)
    puts ""
    puts "="*40
    puts desc
    puts "="*40
  end

  def measure_time_load_random_seats(cars_n)
    cs = generate_cars(cars_n)

    print_desc("time measurements for load #{cars_n} cars, random seats")
    Benchmark.bmbm { |x|
      x.report("load cars random seats"){
        described_class.new(cs)
      }
    }
  end

  def measure_time_load_same_seats(cars_n)
    seats = 6
    cs = generate_cars(cars_n, seats)

    print_desc("time measurements for load #{cars_n} cars, same seats #{seats}")
    Benchmark.bmbm { |x|
      x.report("load cars same seats"){
        described_class.new(cs)
      }
    }
  end

  it 'load cars time measurements' do
    measure_time_load_random_seats(0)
    measure_time_load_random_seats(1_000)
    measure_time_load_random_seats(10_000)
    measure_time_load_random_seats(100_000)
    measure_time_load_random_seats(1_000_000)

    measure_time_load_same_seats(0)
    measure_time_load_same_seats(1_000)
    measure_time_load_same_seats(10_000)
    measure_time_load_same_seats(100_000)
    measure_time_load_same_seats(1_000_000)
  end

  def measure_action_times(cars_n, groups_n)
    cs = generate_cars(cars_n)
    gs = generate_groups(groups_n)
    s = described_class.new(cs)
    add_groups(s, gs)

    print_desc("time measurements for #{cars_n} cars, #{groups_n} groups")
    dropped_ids = Set.new
    Benchmark.bmbm { |x|
      x.report("locate group car"){
        id = nil
        loop do
          id = gs.sample[:id]
          break if !dropped_ids.include?(id)
        end
        s.locate_car_by_group_id(id)
      }
      x.report("add journey"){
        g = random_group
        s.add_group_journey(g[:id], g[:people])
      }
      x.report("dropoff group"){
        id = nil
        loop do
          id = gs.sample[:id]
          break if dropped_ids.add?(id)
        end
        s.dropoff_group_by_id(id)
      }
    }
  end

  it 'action time measurements' do
    measure_action_times(0, 2)
    measure_action_times(0, 1_000)
    measure_action_times(0, 10_000)
    measure_action_times(0, 100_000)
    measure_action_times(0, 1_000_000)

    measure_action_times(0, 2)
    measure_action_times(1_000, 2)
    measure_action_times(10_000, 2)
    measure_action_times(100_000, 2)
    measure_action_times(1_000_000, 2)

    measure_action_times(0, 2)
    measure_action_times(1_000, 1_000)
    measure_action_times(10_000, 10_000)
    measure_action_times(100_000, 100_000)
    measure_action_times(1_000_000, 1_000_000)
  end

  def measure_memory(cars_n, groups_n)
    gs = generate_groups(groups_n)
    cs = generate_cars(cars_n)

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
    cars = generate_cars(n)
    groups = generate_groups(n)

    profile = RubyProf::Profile.new
    profile.exclude_common_methods!
    profile.start

    gs = generate_groups(n)
    cs = generate_cars(n)
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
