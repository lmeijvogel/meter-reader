class DatabaseWriter
  def initialize(database_connection)
    @database_connection = database_connection
  end

  def save(measurement)
    c = @database_connection
    query = <<-QUERY
      INSERT INTO measurements(time_stamp, stroom_dal, stroom_piek, stroom_current, gas) VALUES('#{c.escape measurement.time_stamp.to_s}',
      '#{c.escape measurement.stroom_dal.to_f.to_s}',
      '#{c.escape measurement.stroom_piek.to_f.to_s}',
      '#{c.escape measurement.stroom_current.to_f.to_s}',
      '#{c.escape measurement.gas.to_f.to_s}'
      )
    QUERY
    @database_connection.query( query )
  end
end
