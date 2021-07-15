require 'date'
require 'redis'
require "spec_helper"

require 'current_water_usage_store';

class WaterMeasurement < Struct.new(:water, :time_stamp_utc)
end

describe CurrentWaterUsageStore do
  let(:test_redis_key) { "test_redis_key" }

  let(:store) { CurrentWaterUsageStore.new(redis_list_name: test_redis_key) }

  before do
    redis = Redis.new(host: ENV.fetch("REDIS_HOST"))
    redis.del test_redis_key
    redis.close
  end

  it "return 0 if there are no entries" do
    expect(store.usage).to eq 0
  end

  it "returns 1 if one liter was used in the last minute" do
    at_start = minutes_ago(1.5)

    store.add(WaterMeasurement.new(0, at_start))

    just_now = minutes_ago(1)

    store.add(WaterMeasurement.new(1, just_now))

    expect(store.usage).to eq 1
  end

  it "returns 0 if one liter was used 10 minutes ago" do
    long_ago = minutes_ago(10)

    store.add(WaterMeasurement.new(0, long_ago))

    just_now = minutes_ago(1)

    store.add(WaterMeasurement.new(1, just_now))

    expect(store.usage).to eq 0
  end

  it "returns 100 in a more complex case" do
    long_ago = minutes_ago(10)

    store.add(WaterMeasurement.new(0, minutes_ago(10)))
    store.add(WaterMeasurement.new(25, minutes_ago(9)))
    store.add(WaterMeasurement.new(50, minutes_ago(1.5)))
    store.add(WaterMeasurement.new(100, minutes_ago(1.2)))
    store.add(WaterMeasurement.new(150, minutes_ago(1)))

    expect(store.usage).to eq 100
  end

  def minutes_ago(count)
    minute = 1.0 / 24 / 60
    DateTime.now - (count * minute)
  end
end

