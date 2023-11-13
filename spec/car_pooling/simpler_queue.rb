require 'car_pooling/waiting_queue'

module CarPooling
  class SimplerQueue
    def initialize
      @h = {}
    end

    def length
      @h.length
    end

    def enqueue(id, space)
      raise WaitingQueue::Duplicate.new if @h.has_key?(id)
      @h[id] = space
      nil
    end

    def next_fitting_in(space)
      @h.find{|id, s| s <= space}
    end

    def remove(id)
      @h.delete(id){|id| raise WaitingQueue::Missing.new}
      nil
    end

    def to_a
      @h.to_a
    end
  end
end
