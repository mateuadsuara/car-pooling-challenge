module CarPooling
  class WaitingQueue
    class Duplicate < StandardError; end
    class Missing < StandardError; end

    def initialize(precreate_queues_for_spaces = 1..6)
      @queues_by_space = {}

      #create queues now for the expected amounts of people
      #per group so we avoid cloning queues on enqueue for
      #a new amount of people
      precreate_queues_for_spaces.each do |space|
        @queues_by_space[space] = {}
      end
    end

    def length
      biggest_queue&.length || 0
    end

    def enqueue(id, space)
      bs = biggest_space
      bq = biggest_queue(bs)
      raise Duplicate.new if bq&.has_key?(id)

      if bq.nil?
        @queues_by_space[space] = {}
      elsif space > bs
        @queues_by_space[space] = bq.clone
      elsif !@queues_by_space.has_key?(space)
        @queues_by_space[space] = {}
      end

      @queues_by_space.each do |queue_space, queue|
        if queue_space >= space
          queue[id] = space
        end
      end

      nil
    end

    def next_fitting_in(space)
      ss = smallest_space
      return nil unless ss

      i = space
      while i >= ss
        queue_space = i
        queue = @queues_by_space[queue_space]
        if queue
          queue.each do |id, s|
            return [id, s]
          end
        end

        i -= 1
      end

      nil
    end

    def remove(id)
      (biggest_queue || {}).delete(id){raise Missing.new}
      @queues_by_space.each do |space, queue|
        queue.delete(id)
      end

      nil
    end

    def to_a
      biggest_queue.to_a
    end

    private

    def spaces
      @queues_by_space.keys
    end

    def smallest_space(ks = nil)
      ks ||= spaces
      ks.min
    end

    def biggest_space(ks = nil)
      ks ||= spaces
      ks.max
    end

    def biggest_queue(bs = nil)
      bs ||= biggest_space
      @queues_by_space[bs]
    end
  end
end
