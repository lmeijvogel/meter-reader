class Recorder
  def initialize(environment)
    database_connection = Mysql2::Client.new(DatabaseConfig.for(environment))

    self.database_writer = DatabaseWriter.new(database_connection)
    self.database_writer.save_interval = 15
    self.last_measurement_store = LastMeasurementStore.new
    self.meterstanden_parser = MeasurementParser.new

    if environment == "production"
      self.stream_splitter = StreamSplitter.new(serial_port, "/XMX5XMXABCE100129872")
    else
      self.stream_splitter = FakeStreamSplitter.new
    end
  end

  def collect_data
    loop do
      message = stream_splitter.read

      measurement = meterstanden_parser.parse(message)
      database_writer.save_unless_exists(measurement)
      last_measurement_store.save(measurement)
    end
  end

  protected
  attr_accessor :database_writer, :last_measurement_store, :meterstanden_parser, :stream_splitter

  private
  def serial_port
    serial_port = SerialPort.new("/dev/ttyUSB0", 9600)
    serial_port.data_bits = 7
    serial_port.stop_bits = 1
    serial_port.parity = SerialPort::EVEN

    serial_port
  end
end
