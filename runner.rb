require 'yaml'
require 'ostruct'
require 'serialport'
require 'mysql2'
require 'trollop'

require_relative "models/meterstand.rb"
require_relative "lib/data_parsing/stream_splitter.rb"
require_relative "lib/output/database_writer.rb"

opts = Trollop::options do
  opt :stdin, "Read from stdin"
  opt :env, "Environment", default: "development"
end

if opts[:stdin]
  input = $stdin
else
  serial_port = SerialPort.new("/dev/ttyUSB0", 9600)
  serial_port.data_bits = 7
  serial_port.stop_bits = 1
  serial_port.parity = SerialPort::EVEN

  input = serial_port
end

meterstand_parser = Meterstand.new
stream_splitter = StreamSplitter.new(input, "/XMX5XMXABCE100129872")

config = YAML.load(File.read("database.yml"))[opts[:env]]

database_connection = Mysql2::Client.new(host: config["host"],
                                               database: config["database"],
                                               username: config["username"],
                                               password: config["password"])

database_writer = DatabaseWriter.new(database_connection)

loop do
  message = stream_splitter.read

  measurement = meterstand_parser.parse(message)
  database_writer.save(measurement)
  puts measurement
end
