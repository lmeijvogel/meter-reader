require 'pathname'
require 'mysql2'
require 'dotenv'

$LOAD_PATH << File.expand_path("../lib", __FILE__)

require "p1_meter_reader"
require "output/database_writer"
require "output/last_measurement_store"
require "database_config"

ROOT_PATH = Pathname.new File.dirname(__FILE__)

Dotenv.load

class DatabaseConnectionFactory
  def initialize(environment)
    @environment = environment
  end

  def create
    with_retries(log_message_format: "Retrying SQL connection (%d/%d)") do
      Mysql2::Client.new(DatabaseConfig.for(@environment))
    end
  end

  private

  def with_retries(max_tries: 5, log_message_format: "Retrying (%d/%d)")
    tries = 0
    retry_interval = 2

    begin
      yield
    rescue Mysql2::Error
      tries += 1

      if tries > max_tries
        raise
      end

      puts format(log_message_format, tries, max_tries)
      sleep retry_interval

      retry_interval *= 2

      retry
    end
  end

end

def main
  environment = ENV.fetch('ENVIRONMENT')

  database_writer = DatabaseWriter.new(DatabaseConnectionFactory.new(environment))
  database_writer.save_interval = 15

  last_measurement_store = LastMeasurementStore.new

  if environment == "production"
    stream_splitter = P1MeterReader::DataParsing::StreamSplitter.new("/XMX5XMXABCE100129872")
    water_data_source = P1MeterReader::DataParsing::WaterMeasurementListener.new
  else
    puts "Fake stream splitter"
    stream_splitter = P1MeterReader::DataParsing::FakeStreamSplitter.new
    water_data_source = P1MeterReader::DataParsing::FakeWaterMeasurementListener.new
  end

  recorder = P1MeterReader::Recorder.new(
    p1_data_source: stream_splitter,
    water_data_source: water_data_source
  )

  recorder.collect_data do |measurement|
    database_writer.save_unless_exists(measurement)
    last_measurement_store.save(measurement)
  end
end

puts "Starting..."
main
