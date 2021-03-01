require 'json'
require 'redis'

# Less than 1/2 liter per minute is negligible
WATER_USAGE_PERIOD_IN_SECONDS = 120

class CurrentWaterUsageStore
  def initialize(redis_list_name: "current_water_usage", last_ticks_var_name: "last_water_usage_ticks")
    @usage = 0
    @redis_list_name = redis_list_name
    @last_ticks_var_name = last_ticks_var_name
  end

  def period_in_seconds
    WATER_USAGE_PERIOD_IN_SECONDS
  end

  def usage
    with_redis do |redis|
      remove_outdated_items(redis)

      first_entry = redis.lrange(@redis_list_name, 0, 0)
      last_entry = redis.lrange(@redis_list_name, -1, -1)

      return 0 if first_entry.empty?

      JSON.parse(last_entry[0])["water"] - JSON.parse(first_entry[0])["water"]
    end
  end

  def add(measurement)
    with_redis do |redis|
      remove_outdated_items(redis)

      redis_data = {
        water: measurement.water,
        time_stamp_utc: measurement.time_stamp_utc
      }

      redis.rpush(@redis_list_name, redis_data.to_json)
      last_entry = redis.lrange(@redis_list_name, 0, 0)[0]
    end
  end

  def add_tick(timestamp)
    with_redis do |redis|
      redis.multi do
        redis.lpush(@last_ticks_var_name, timestamp)

        redis.ltrim @last_ticks_var_name, 0, 1
      end
    end
  end

  private def remove_outdated_items(redis)
    cutoff_time = DateTime.now - period_in_days

    loop do
      begin
        entry_json = redis.lrange(@redis_list_name, 0, 0)[0]

        break if entry_json.nil?

        entry = JSON.parse(entry_json)

        time_stamp_string = entry["time_stamp_utc"]
        time_stamp_utc = DateTime.parse(time_stamp_string)

        # Items are time-ordered: If the current item is after the cutoff time,
        # any following items will also be after the cutoff time
        break if cutoff_time < time_stamp_utc

        redis.lpop @redis_list_name
      rescue StandardError => e
        # Delete any unreadable entries
        redis.lpop @redis_list_name
      end
    end
  end

  private def with_redis
    redis = Redis.new

    yield redis
  ensure
    redis.close
  end

  private def period_in_days
    period_in_seconds * (1.0 / 24 / 60 / 60)
  end
end
