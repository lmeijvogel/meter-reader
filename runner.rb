require 'pathname'
require 'mysql2'
require 'dotenv'

$LOAD_PATH << "lib"
require "p1_meter_reader"
require "output/database_writer"
require "output/last_measurement_store"
require "database_config"

ROOT_PATH = Pathname.new File.dirname(__FILE__)

Dotenv.load

environment = ENV.fetch('ENVIRONMENT')

database_connection = Mysql2::Client.new(DatabaseConfig.for(environment))

database_writer = DatabaseWriter.new(database_connection)
database_writer.save_interval = 15

last_measurement_store = LastMeasurementStore.new

if environment == "production"
  stream_splitter = P1MeterReader::DataParsing::StreamSplitter.new("/XMX5XMXABCE100129872")
else
  stream_splitter = P1MeterReader::DataParsing::FakeStreamSplitter.new
end

recorder = P1MeterReader::Recorder.new(measurement_source: stream_splitter)

recorder.collect_data do |measurement|
  database_writer.save_unless_exists(measurement)
  last_measurement_store.save(measurement)
end
