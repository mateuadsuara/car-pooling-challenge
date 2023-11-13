require 'rspec'

require 'benchmark'

require 'car_pooling/waiting_queue'
require 'car_pooling/simpler_queue'

RSpec.describe CarPooling::WaitingQueue, performance: true do
  def enqueue_many(queue, n, space = nil, start_id: 0)
    (start_id..(start_id+n)).each do |id|
      s = space&.call || space || (1..6).to_a.sample
      queue.enqueue(id, s)
    end
  end

  def print_desc(desc)
    puts ""
    puts "="*40
    puts desc
    puts "="*40
  end

  it 'enqueue time measurements' do
    measure_enqueue = Proc.new do |queue|
      Benchmark.bmbm { |x|
        x.report("enqueue biggest space"){
          queue.enqueue(rand, 6)
        }
        x.report("enqueue smallest space"){
          queue.enqueue(rand, 1)
        }
        x.report("enqueue valid space"){
          queue.enqueue(rand, (1..6).to_a.sample)
        }
        x.report("enqueue same bigger than biggest space"){
          queue.enqueue(rand, 10)
        }
        x.report("enqueue different bigger than biggest space"){
          queue.enqueue(rand, (10..9999).to_a.sample)
        }
        x.report("enqueue different smaller than smallest space"){
          queue.enqueue(rand, (-9999..0).to_a.sample)
        }
      }
    end

    print_desc("n = 1_000_000, time for another enqueue on simpler queue")
    simpler = CarPooling::SimplerQueue.new
    enqueue_many(simpler, 1_000_000, lambda{rand(5)+1})
    measure_enqueue.call(simpler)

    print_desc("n = 1_000_000, time for another enqueue on efficient version")
    efficient = described_class.new
    enqueue_many(efficient, 1_000_000, lambda{rand(5)+1})
    measure_enqueue.call(efficient)
  end

  it 'next_fitting_in time measurements' do
    measure_next_fitting_in = Proc.new do |queue|
      Benchmark.bmbm { |x|
        x.report("next_fitting_in finds one from the start in queue"){
          queue.next_fitting_in(4)
        }
        x.report("next_fitting_in finds smallest last in queue"){
          queue.next_fitting_in(1)
        }
        x.report("next_fitting_in finds biggest last in queue"){
          queue.next_fitting_in(6)
        }
      }
    end

    print_desc("n = 1_000_000, time for next_fitting_in on simpler queue")
    simpler = CarPooling::SimplerQueue.new
    enqueue_many(simpler, 1_000_000, lambda{(2..5).to_a.sample})
    simpler.enqueue(1_000_001, 6)
    simpler.enqueue(1_000_002, 1)
    measure_next_fitting_in.call(simpler)

    print_desc("n = 1_000_000, time for next_fitting_in on efficient queue")
    efficient = described_class.new
    enqueue_many(efficient, 1_000_000, lambda{(2..5).to_a.sample})
    efficient.enqueue(1_000_001, 6)
    efficient.enqueue(1_000_002, 1)
    measure_next_fitting_in.call(efficient)
  end

  it 'remove time measurements' do
    measure_remove = Proc.new do |queue|
      Benchmark.bm { |x|
        x.report("remove first in queue"){
          queue.remove(1)
        }
        x.report("remove middle in queue"){
          queue.remove(1_000_000 / 2)
        }
        x.report("remove last in queue"){
          queue.remove(1_000_000)
        }
      }
    end

    print_desc("n = 1_000_000, time for remove on simpler queue")
    simpler = CarPooling::SimplerQueue.new
    enqueue_many(simpler, 1_000_000 + 1)
    measure_remove.call(simpler)

    print_desc("n = 1_000_000, time for remove on efficient queue")
    efficient = described_class.new
    enqueue_many(efficient, 1_000_000 + 1)
    measure_remove.call(efficient)
  end
end
