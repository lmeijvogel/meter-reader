require 'pathname'
require 'mysql2'
require 'dotenv'
require 'json'
require 'serialport'

$LOAD_PATH << File.expand_path("../lib", __FILE__)

require "p1_meter_reader/data_parsing/stream_splitter"
require "p1_meter_reader/data_parsing/fake_stream_splitter"
require "water_measurement_store"
require "p1_meter_reader/recorder"

require "database_connection_factory"
require "database_reader"
require "output/database_writer"

require "recent_measurement_store"

# Used by DatabaseConfig
ROOT_PATH = Pathname.new File.dirname(__FILE__)

Dotenv.load

def main
  environment = ENV.fetch('ENVIRONMENT')

  measurement_counter = 0

  database_writer = DatabaseWriter.new(DatabaseConnectionFactory.new(environment))
  database_writer.save_interval = 5

  recent_measurement_store = RecentMeasurementStore.new(
    number_of_entries: 8 * 60, # 8 hours at 1 measurement per minute
    redis_host: ENV.fetch("REDIS_HOST"),
    redis_list_name: ENV.fetch("REDIS_MEASUREMENTS_LIST_NAME")
  )

  last_measurement = :no_last_measurement

  water_measurement_store = WaterMeasurementStore.new(
    redis_host: ENV.fetch("REDIS_HOST"),
  )

  if environment == "production"
    stream_splitter = P1MeterReader::DataParsing::StreamSplitter.new(ENV.fetch("P1_CONVERTER_MESSAGE_START"), input: serial_port)

    current_measurement_echoer = ->(measurement) { }
  else
    log "Fake stream splitter"
    stream_splitter = P1MeterReader::DataParsing::FakeStreamSplitter.new
    current_measurement_echoer = ->(measurement) { log measurement.to_s }
  end

  recorder = P1MeterReader::Recorder.new(
    p1_data_source: stream_splitter
  )

  recorder.collect_data do |measurement|
    if valid?(measurement, last_measurement)
      measurement.water = water_measurement_store.get

      database_writer.save_unless_exists(measurement)

      json = measurement_to_json(measurement, measurement_counter)
      recent_measurement_store.add(json)

      measurement_counter += 1

      last_measurement = measurement

      current_measurement_echoer.(measurement)
    end
  end
end

def measurement_to_json(measurement, measurement_counter)
  stroom = measurement.stroom_dal.to_f + measurement.stroom_piek.to_f

  {
    id:               measurement_counter,
    time_stamp:       measurement.time_stamp.to_s,
    time_stamp_utc:   measurement.time_stamp_utc.to_s,
    stroom:           stroom,
    stroom_current:   measurement.stroom_current.to_f,
    gas:              measurement.gas.to_f,
    water:            measurement.water.to_f
  }.to_json
end

def valid?(measurement, last_measurement)
  if last_measurement == :no_last_measurement
    measurement_not_zero?(measurement)
  else
    # The new meter is a bit less trustworthy and will sometimes report
    # invalid energy measurements, e.g. 0 or less than it should
    return false if measurement.stroom_dal.nil? || measurement.stroom_dal.to_f < last_measurement.stroom_dal.to_f
    return false if measurement.stroom_piek.nil? || measurement.stroom_piek.to_f < last_measurement.stroom_piek.to_f
    return false if measurement.gas.nil? || measurement.gas.to_f < last_measurement.gas.to_f

    true
  end
end

def measurement_not_zero?(measurement)
  return false if measurement.stroom_dal.nil? || measurement.stroom_dal.to_f.to_i.abs < 0.01
  return false if measurement.stroom_piek.nil? || measurement.stroom_piek.to_f.to_i.abs < 0.01
  return false if measurement.gas.nil? || measurement.gas.to_i.abs < 0.01

  true
end

def serial_port
  device = ENV.fetch("P1_CONVERTER_DEVICE")
  baud_rate = Integer(ENV.fetch("P1_CONVERTER_BAUD_RATE"))

  serial_port = SerialPort.new(device, baud_rate)
  serial_port.data_bits = 7
  serial_port.stop_bits = 1
  serial_port.parity = SerialPort::EVEN

  serial_port
end

def log(message)
  $stdout.puts message
  $stdout.flush
end

puts "Starting..."
main