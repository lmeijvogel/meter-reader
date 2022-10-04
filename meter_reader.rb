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
require "output/influxdb_client"

require "recent_measurement_store"

# Used by DatabaseConfig
ROOT_PATH = Pathname.new File.dirname(__FILE__)

Dotenv.load

def main
  environment = ENV.fetch('ENVIRONMENT')

  reading_counter = 0

  database_connection_factory = DatabaseConnectionFactory.new(environment)
  database_writer = DatabaseWriter.new(database_connection_factory)
  database_writer.save_interval = 5

  recent_reading_store = RecentMeasurementStore.new(
    number_of_entries: 8 * 60, # 8 hours at 1 reading per minute
    redis_host: ENV.fetch("REDIS_HOST"),
    redis_list_name: ENV.fetch("REDIS_MEASUREMENTS_LIST_NAME")
  )

  last_reading = :no_last_reading

  water_reading_store = WaterMeasurementStore.new(
    redis_host: ENV.fetch("REDIS_HOST"),
  )

  if environment == "production"
    stream_splitter = P1MeterReader::DataParsing::StreamSplitter.new(ENV.fetch("P1_CONVERTER_MESSAGE_START"), input: serial_port)

    current_reading_echoer = ->(reading) { }
  else
    log "Fake stream splitter"
    stream_splitter = P1MeterReader::DataParsing::FakeStreamSplitter.new
    current_reading_echoer = ->(reading) { log "Received reading: #{reading}"}

    # Timecop.scale(360)
  end

  recorder = P1MeterReader::Recorder.new(
    p1_data_source: stream_splitter
  )

  influx = InfluxDBClient.new(hostname: ENV.fetch("INFLUXDB_HOST"), org: ENV.fetch("INFLUXDB_ORG"), bucket: ENV.fetch("INFLUXDB_BUCKET"), token: ENV.fetch("INFLUXDB_TOKEN"))

  recorder.collect_data do |reading|
    if valid?(reading, last_reading)
      reading.water = water_reading_store.get

      database_writer.save_unless_exists(reading)

      json = reading_to_json(reading, reading_counter)
      recent_reading_store.add(json)

      reading_counter += 1

      begin
        if last_reading != :no_last_reading
          influx.send_gas_reading(reading.gas) if reading.gas > last_reading.gas

          stroom = reading.stroom_dal.to_f + reading.stroom_piek.to_f
          levering = reading.levering_dal.to_f + reading.levering_piek.to_f
          last_stroom = last_reading.stroom_dal.to_f + last_reading.stroom_piek.to_f
          last_levering = last_reading.levering_dal.to_f + last_reading.levering_piek.to_f

          influx.send_stroom_reading(stroom) if stroom > last_stroom

          influx.send_current_reading(reading.stroom_current) # Always send current

          # Water is sent separately in the water runner
        end
      rescue StandardError => e
        $stdout.puts "ERROR sending to InfluxDB: #{e.message}"
      end

      last_reading = reading

      current_reading_echoer.(reading)
    end
  end
end

def reading_to_json(reading, reading_counter)
  stroom = reading.stroom_dal.to_f + reading.stroom_piek.to_f
  levering = reading.levering_dal.to_f + reading.levering_piek.to_f

  {
    id:               reading_counter,
    time_stamp:       reading.time_stamp.to_s,
    time_stamp_utc:   reading.time_stamp_utc.to_s,
    stroom:           stroom,
    levering:         levering,
    stroom_current:   reading.stroom_current.to_f,
    gas:              reading.gas.to_f,
    water:            reading.water.to_f
  }.to_json
end

def valid?(reading, last_reading)
  if last_reading == :no_last_reading
    reading_not_zero?(reading)
  else
    # The new meter is a bit less trustworthy and will sometimes report
    # invalid energy readings, e.g. 0 or less than it should
    return false if reading.stroom_dal.nil? || reading.stroom_dal.to_f < last_reading.stroom_dal.to_f
    return false if reading.stroom_piek.nil? || reading.stroom_piek.to_f < last_reading.stroom_piek.to_f
    # Do not enable these yet since there is no levering yet :D
    # return false if reading.levering_dal.nil? || reading.levering_dal.to_f < last_reading.levering_dal.to_f
    # return false if reading.levering_piek.nil? || reading.levering_piek.to_f < last_reading.levering_piek.to_f
    return false if reading.gas.nil? || reading.gas.to_f < last_reading.gas.to_f

    true
  end
end

def reading_not_zero?(reading)
  return false if reading.stroom_dal.nil? || reading.stroom_dal.to_f.to_i.abs < 0.01
  return false if reading.stroom_piek.nil? || reading.stroom_piek.to_f.to_i.abs < 0.01
  # Do not enable yet
  # return false if reading.levering_dal.nil? || reading.levering_dal.to_f.to_i.abs < 0.01
  # return false if reading.levering_piek.nil? || reading.levering_piek.to_f.to_i.abs < 0.01
  return false if reading.gas.nil? || reading.gas.to_i.abs < 0.01

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
