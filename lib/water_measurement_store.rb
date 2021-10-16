require 'date'
require 'redis'

class WaterMeasurementStore
  def initialize(redis_host:, measurements_redis_key:)
    @redis_host = redis_host
    @measurements_redis_key = measurements_redis_key
  end

  def get
    with_redis do |redis|
      Integer(redis.get(@measurements_redis_key))
    end
  end

  def set(value)
    with_redis do |redis|
      redis.set(@measurements_redis_key, Integer(value))
    end
  end

  private

  def with_redis
    redis = Redis.new(host: @redis_host)

    yield redis
  ensure
    redis.close
  end

end
