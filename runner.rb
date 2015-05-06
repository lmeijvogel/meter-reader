require 'pathname'
require 'serialport'
require 'mysql2'
require 'dotenv'

$LOAD_PATH << "lib"
require "p1_meter_reader/data_parsing/stream_splitter"
require "p1_meter_reader/data_parsing/fake_stream_splitter"
require "output/database_writer"
require "output/last_measurement_store"
require "database_config"
require "p1_meter_reader/recorder"

ROOT_PATH = Pathname.new File.dirname(__FILE__)

Dotenv.load

environment = ENV.fetch('ENVIRONMENT')

database_connection = Mysql2::Client.new(DatabaseConfig.for(environment))

database_writer = DatabaseWriter.new(database_connection)
database_writer.save_interval = 15

last_measurement_store = LastMeasurementStore.new

if environment == "production"
  stream_splitter = StreamSplitter.new(serial_port, "/XMX5XMXABCE100129872")
else
  stream_splitter = FakeStreamSplitter.new
end

recorder = Recorder.new(measurement_source: stream_splitter)

recorder.collect_data do |measurement|
  database_writer.save_unless_exists(measurement)
  last_measurement_store.save(measurement)
end
