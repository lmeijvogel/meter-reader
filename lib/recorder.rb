class MeterstandenRecorder
  def initialize(environment)
    database_connection = Mysql2::Client.new(DatabaseConfig.for(environment))

    self.database_writer = DatabaseWriter.new(database_connection)
    self.database_writer.save_interval = 15
    self.redis_writer    = RedisWriter.new
    self.meterstanden_parser = Meterstand.new

    self.stream_splitter = StreamSplitter.new(serial_port, "/XMX5XMXABCE100129872")
  end

  def collect_data
    loop do
      message = stream_splitter.read

      measurement = meterstanden_parser.parse(message)
      database_writer.save_unless_exists(measurement)
      redis_writer.save(measurement)
    end
  end

  protected
  attr_accessor :database_writer, :redis_writer, :meterstanden_parser, :stream_splitter

  private
  def serial_port
    serial_port = SerialPort.new("/dev/ttyUSB0", 9600)
    serial_port.data_bits = 7
    serial_port.stop_bits = 1
    serial_port.parity = SerialPort::EVEN

    serial_port
  end
end
