require 'rspec'
require 'date'

$LOAD_PATH << File.dirname(__FILE__)

require 'current_water_usage_calculator.rb'

describe CurrentWaterUsageCalculator do
  it "should return 0 if there are fewer than 2 measurements" do
    expect(CurrentWaterUsageCalculator.calculate([])).to eql 0
    expect(CurrentWaterUsageCalculator.calculate(measurements(1))).to eql 0
  end

  it "should return 1" do
    expect(CurrentWaterUsageCalculator.calculate(measurements(1, 61))).to be_within(0.1).of(1)
  end

  # It's taking longer to receive a tick than we would expect
  it "should return 2 if water usage is decreasing" do
    expect(CurrentWaterUsageCalculator.calculate(measurements(31, 51))).to be_within(0.1).of(2)
  end

  # The next tick could still come at the expected time
  it "should return 3 if water usage is not known to be decreasing" do
    expect(CurrentWaterUsageCalculator.calculate(measurements(1, 21))).to be_within(0.1).of(3)
    expect(CurrentWaterUsageCalculator.calculate(measurements(11, 31))).to be_within(0.1).of(3)
  end

  it "should round to the closest 0.5l" do
    # Exactly 2.5
    expect(CurrentWaterUsageCalculator.calculate(measurements(23, 47))).to be_within(0.1).of(2.5)

    # Slightly more - Should round down
    expect(CurrentWaterUsageCalculator.calculate(measurements(25, 47))).to be_within(0.1).of(2.5)
    # Slightly less - Should round up
    expect(CurrentWaterUsageCalculator.calculate(measurements(21, 47))).to be_within(0.1).of(2.5)
  end

  def measurements(*timestamps)
    timestamps.map { |ts| seconds_ago(ts) }
  end

  def seconds_ago(count)
    second = 1.0 / 24 / 60 / 60
    DateTime.now - (count * second)
  end
end
