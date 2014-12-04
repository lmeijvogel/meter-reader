require 'redis'
require 'json'

class RedisWriter
  def initialize
    @counter = 0
  end

  def save(measurement)
    redis_connection = Redis.new

    hash = {
      id:               @counter,
      time_stamp:       measurement.time_stamp.to_s,
      time_stamp_utc:   measurement.time_stamp_utc.to_s,
      stroom_dal:       measurement.stroom_dal.to_f,
      stroom_piek:      measurement.stroom_piek.to_f,
      stroom_current:   measurement.stroom_current.to_f,
      diff_stroom_dal:  measurement.diff_stroom_dal.to_f,
      diff_stroom_piek: measurement.diff_stroom_piek.to_f,
      gas:              measurement.gas.to_f
    }

    redis_connection.set("measurement", hash.to_json)
    @counter += 1
  end
end
