require 'models/usage'

class DatabaseReader
  def initialize(connection_factory)
    @connection_factory = connection_factory
  end

  def last_measurement
    query = <<~QUERY
      SELECT
        time_stamp AS ts,
        stroom AS d_stroom,
        gas AS d_gas,
        water AS d_water
      FROM measurements
      WHERE id = (SELECT MAX(id) FROM measurements)
    QUERY

    @connection_factory.with_connection do |connection|
      row = connection.query(query).first

      return to_usage(row)
    end
  end

  private

  def to_usage(row)
    usage = P1MeterReader::Models::Usage.new
    usage.stroom = row["d_stroom"]
    usage.gas = row["d_gas"]
    usage.water = row["d_water"]
    usage.time_stamp = row["ts"].to_datetime
    usage.label = row["label"]

    usage
  end
end
