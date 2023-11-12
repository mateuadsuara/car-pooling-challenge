module KeyedQueue
  def self.new
    Container.new
  end

  class Duplicate < StandardError; end
  class Missing < StandardError; end

  class Container
    def initialize
      @h = {}
    end

    def length
      @h.length
    end

    def push(e)
      raise Duplicate.new if @h.has_key?(e)
      @h[e] = nil
    end

    def each(&block)
      @h.each{|k, _| block.call(k)}
    end

    def remove(e)
      @h.delete(e){|e| raise Missing.new}
    end

    def to_a
      @h.keys
    end
  end
end
