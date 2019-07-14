require 'redis'

class TemporaryMeasurementStore
  def initialize(number_of_entries:, redis_list_name: "latest_measurements")
    @number_of_entries = number_of_entries
    @redis_list_name = redis_list_name

    @redis = Redis.new
  end

  def add(measurement)
    @redis.multi do
      @redis.lpush @redis_list_name, measurement
      @redis.ltrim @redis_list_name, 0, @number_of_entries
    end
  end

  alias_method :<<, :add

  def measurements
    @redis = Redis.new

    @redis.lrange @redis_list_name, 0, @number_of_entries
  end
end
