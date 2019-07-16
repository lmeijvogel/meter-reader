require 'pathname'
require 'mysql2'
require 'dotenv'

$LOAD_PATH << File.expand_path("../lib", __FILE__)

require "p1_meter_reader"
require "database_connection_factory"
require "database_reader"
require "output/database_writer"
require "output/last_measurement_store"
require "database_config"

require "recent_measurement_store"

ROOT_PATH = Pathname.new File.dirname(__FILE__)

Dotenv.load

def get_last_water_measurement(environment)
  database_reader = DatabaseReader.new(DatabaseConnectionFactory.new(environment))

  database_reader.last_measurement.water
end

def main
  environment = ENV.fetch('ENVIRONMENT')

  measurement_counter = 0

  database_writer = DatabaseWriter.new(DatabaseConnectionFactory.new(environment))
  database_writer.save_interval = 15

  last_measurement_store = LastMeasurementStore.new
  recent_measurement_store = RecentMeasurementStore.new(
    number_of_entries: 8 * 60, # 8 hours at 1 measurement per minute
    redis_list_name: ENV.fetch("REDIS_LIST_NAME")
  )

  last_water_measurement = 0

  if environment == "production"
    last_water_measurement = get_last_water_measurement(environment)

    stream_splitter = P1MeterReader::DataParsing::StreamSplitter.new("/XMX5XMXABCE100129872")
    water_data_source = P1MeterReader::DataParsing::WaterMeasurementListener.new
  else
    puts "Fake stream splitter"
    stream_splitter = P1MeterReader::DataParsing::FakeStreamSplitter.new
    water_data_source = P1MeterReader::DataParsing::FakeWaterMeasurementListener.new
  end

  water_measurement_parser = P1MeterReader::Models::WaterMeasurementParser.new(last_water_measurement)

  recorder = P1MeterReader::Recorder.new(
    p1_data_source: stream_splitter,
    water_data_source: water_data_source,
    water_measurement_parser: water_measurement_parser
  )

  recorder.collect_data do |measurement|
    json = measurement_to_json(measurement, measurement_counter)

    database_writer.save_unless_exists(measurement)
    last_measurement_store.save(json)
    recent_measurement_store.add(json)

    measurement_counter += 1
  end
end

def measurement_to_json(measurement, measurement_counter)
  {
    id:               measurement_counter,
    time_stamp:       measurement.time_stamp.to_s,
    time_stamp_utc:   measurement.time_stamp_utc.to_s,
    stroom_dal:       measurement.stroom_dal.to_f,
    stroom_piek:      measurement.stroom_piek.to_f,
    stroom_current:   measurement.stroom_current.to_f,
    gas:              measurement.gas.to_f,
    water:            measurement.water.to_f
  }.to_json
end

puts "Starting..."
main
