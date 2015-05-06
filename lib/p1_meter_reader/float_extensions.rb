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
    if other.is_a? Kwh
      (other.value - value) < 0.001
    elsif other.is_a? Float
      (other - value) < 0.001
    else
      false
    end
  end

  def -(other)
    (self.value - other.value).kWh
  end

  def inspect
    "#{value}kWh"
  end

  def to_s
    inspect
  end

  def to_f
    value
  end

  protected
  attr_accessor :value
end
