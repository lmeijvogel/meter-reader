require 'redis'

class RecentMeasurementStore
  def initialize(number_of_entries:, redis_list_name: "latest_measurements")
    @number_of_entries = number_of_entries
    @redis_list_name = redis_list_name

    @wait_until_error_output = 0
    @wait_until_add = 0

    @redis = Redis.new
  end

  def add(measurement)
    if @wait_until_add == 0
      @redis.multi do
        @redis.lpush @redis_list_name, measurement
        @redis.ltrim @redis_list_name, 0, @number_of_entries
      end

      @wait_until_add = 6
    else
      @wait_until_add -= 1
    end

    # No Exceptions happened, so reset the timer
    @wait_until_error_output = 0
  rescue RuntimeError => e
    # Recent measurements are less important than long term data,
    # so ignore errors here.
    if @wait_until_error_output <= 0
      puts "Error while connecting to Redis: #{e.message}"

      @wait_until_error_output = 10
    end
  end

  alias_method :<<, :add

  def measurements
    @redis = Redis.new

    @redis.lrange @redis_list_name, 0, @number_of_entries
  end
end
