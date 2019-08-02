require 'redis'

class RecentMeasurementStore
  def initialize(number_of_entries:, redis_list_name: "latest_measurements")
    @number_of_entries = number_of_entries
    @redis_list_name = redis_list_name

    @wait_until_error_output = 0
    @wait_until_add = 0
  end

  def add(measurement)
    once_every_n_times(6) do
      with_redis do |redis|
        redis.multi do
          redis.lpush @redis_list_name, measurement
          redis.ltrim @redis_list_name, 0, @number_of_entries
        end
      end

      # No Exceptions happened, so reset the timer
      @wait_until_error_output = 0
    end
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
    with_redis do |redis|
      redis.lrange @redis_list_name, 0, @number_of_entries
    end
  end

  private

  def with_redis
    redis = Redis.new

    yield redis
  ensure
    redis.close
  end

  def once_every_n_times(n)
    if @wait_until_add == 0
      yield

      @wait_until_add = n
    else
      @wait_until_add -= 1
    end
  end
end
