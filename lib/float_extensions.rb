class Float
  def kWh
    Kwh.new(self)
  end
end

class Kwh
  def initialize(value)
    self.value = value
  end

  def ==(other)
    other.value == value
  end

  def inspect
    "#{value}kWh"
  end

  protected
  attr_accessor :value
end
