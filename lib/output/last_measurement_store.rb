require 'json'

class LastMeasurementStore
  NoMeasurementFound = Class.new(StandardError)

  def initialize
    @counter = 0
  end

  def load
    File.read(filename)
  rescue Errno::ENOENT
    raise NoMeasurementFound
  end

  def save(measurement)
    hash = {
      id:               @counter,
      time_stamp:       measurement.time_stamp.to_s,
      time_stamp_utc:   measurement.time_stamp_utc.to_s,
      stroom_dal:       measurement.stroom_dal.to_f,
      stroom_piek:      measurement.stroom_piek.to_f,
      stroom_current:   measurement.stroom_current.to_f,
      gas:              measurement.gas.to_f,
      water:            measurement.water.to_f
    }

    File.write(filename, hash.to_json)
    @counter += 1
  end

  private
  def filename
    "/tmp/meter-reader-last-measurement.json"
  end
end
