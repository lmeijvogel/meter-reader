class DatabaseWriter
  attr_accessor :save_interval

  def initialize(database_connection)
    @database_connection = database_connection
    save_interval = 0
  end

  def save_unless_exists(measurement)
    save(measurement) unless exists?(measurement)
  end

  def save(measurement)
    c = @database_connection
    query = <<-QUERY
      INSERT INTO measurements(time_stamp, time_stamp_utc, stroom_dal, stroom_piek, stroom_current, diff_stroom_dal, diff_stroom_piek, gas) VALUES(
      '#{c.escape measurement.time_stamp.to_s}',
      '#{c.escape measurement.time_stamp_utc.to_s}',
      '#{c.escape measurement.stroom_dal.to_f.to_s}',
      '#{c.escape measurement.stroom_piek.to_f.to_s}',
      '#{c.escape measurement.stroom_current.to_f.to_s}',
      '#{c.escape measurement.diff_stroom_dal.to_f.to_s}',
      '#{c.escape measurement.diff_stroom_piek.to_f.to_s}',
      '#{c.escape measurement.gas.to_f.to_s}'
      )
    QUERY

    @database_connection.query( query )
  end

  private
  def exists?(measurement)
    sql_date_format  = "%Y-%m-%d %H:%i:%S"
    ruby_date_format = "%Y-%m-%d %H:%M:%S"

    save_interval_in_days = Float(save_interval)/(24*60)
    previous_half_hour   = measurement.time_stamp - save_interval_in_days

    formatted_start_time = previous_half_hour.strftime(ruby_date_format)
    formatted_end_time   = measurement.time_stamp.strftime(ruby_date_format)

    c = @database_connection
    escaped_start_time  = c.escape formatted_start_time
    escaped_end_time    = c.escape formatted_end_time

    exists_query = <<-QUERY
      SELECT * FROM measurements
      WHERE str_to_date('#{escaped_start_time}', '#{sql_date_format}') < time_stamp
      AND   time_stamp <=  str_to_date('#{escaped_end_time}',   '#{sql_date_format}')
    QUERY

    @database_connection.query(exists_query).any?
  end
end
