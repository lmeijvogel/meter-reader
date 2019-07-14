require 'json'

class LastMeasurementStore
  NoMeasurementFound = Class.new(StandardError)

  def load
    File.read(filename)
  rescue Errno::ENOENT
    raise NoMeasurementFound
  end

  def save(measurement)
    File.write(filename, measurement)
  end

  private
  def filename
    "/tmp/meter-reader-last-measurement.json"
  end
end
