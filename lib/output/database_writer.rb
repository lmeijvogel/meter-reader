class DatabaseWriter
  attr_accessor :save_interval

  def initialize(database_connection_factory)
    @database_connection_factory = database_connection_factory
    self.save_interval = 0
  end

  def save_unless_exists(measurement)
    @database_connection_factory.with_connection do |connection|
      save(measurement, connection) unless exists?(measurement, connection)
    end
  end

  def save(measurement, database_connection)
    stroom = measurement.stroom_dal.to_f + measurement.stroom_piek.to_f
    levering = measurement.levering_dal.to_f + measurement.levering_piek.to_f

    statement = database_connection.prepare <<~QUERY
      INSERT INTO measurements(time_stamp, time_stamp_utc, stroom, levering, gas, water) VALUES(
        ?,
        ?,
        ?,
        ?,
        ?,
        ?)
      QUERY

    statement.execute(
      measurement.time_stamp.strftime('%FT%T'),
      measurement.time_stamp_utc.strftime('%FT%T'),
      stroom,
      levering,
      measurement.gas.to_f,
      measurement.water.to_f
    )

  end

  private

  def exists?(measurement, database_connection)
    sql_date_format  = "%Y-%m-%d %H:%i:%S"
    ruby_date_format = "%Y-%m-%d %H:%M:%S"

    save_interval_in_days = Float(save_interval)/(24*60)
    previous_half_hour   = measurement.time_stamp - save_interval_in_days

    formatted_start_time = previous_half_hour.strftime(ruby_date_format)
    formatted_end_time   = measurement.time_stamp.strftime(ruby_date_format)

    c = database_connection
    escaped_start_time  = c.escape formatted_start_time
    escaped_end_time    = c.escape formatted_end_time

    exists_query = <<~QUERY
      SELECT * FROM measurements
      WHERE str_to_date('#{escaped_start_time}', '#{sql_date_format}') < time_stamp
      AND   time_stamp <=  str_to_date('#{escaped_end_time}',   '#{sql_date_format}')
    QUERY

    database_connection.query(exists_query).any?
  end
end
