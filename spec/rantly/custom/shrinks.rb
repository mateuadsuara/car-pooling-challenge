class DelegateAll < BasicObject
  def initialize(delegated)
    @__internal_delegated__ = delegated
  end

  def method_missing(m, *args, &block)
    @__internal_delegated__.send(m, *args, &block)
  end
end

class ShrinkRange < DelegateAll
  def initialize(delegated, range)
    super(delegated)
    @__internal_shrink_range__ = range
    raise ::ArgumentError.new("Range #{range.inspect} does not include #{delegated.inspect}") unless range.include?(delegated)
  end

  def shrink
    range = @__internal_shrink_range__
    maybe_shrunk = @__internal_delegated__.shrink
    if range.include?(maybe_shrunk)
      ::ShrinkRange.new(maybe_shrunk, range)
    elsif maybe_shrunk > range.max
      ::ShrinkRange.new(range.max, range)
    elsif maybe_shrunk < range.min
      ::ShrinkRange.new(range.min, range)
    else
      self
    end
  end

  def shrinkable?
    range = @__internal_shrink_range__
    range.include?(self) &&
      !(self.eql?(range.min) ||
        self.eql?(range.max))
  end
end
