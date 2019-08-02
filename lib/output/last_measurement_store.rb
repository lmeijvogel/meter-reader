require 'redis'

class LastMeasurementStore
  NoMeasurementFound = Class.new(StandardError)

  def load
    with_redis do |redis|
      redis.get("last_measurement") or raise NoMeasurementFound
    end
  end

  def save(measurement)
    with_redis do |redis|
      redis.set("last_measurement", measurement)
    end
  end

  private

  def with_redis
    redis = Redis.new

    yield redis
  ensure
    redis.close
  end
end
