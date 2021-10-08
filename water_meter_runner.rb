require 'dotenv'

$LOAD_PATH << File.expand_path("./lib")

require "water_reader/water_measurement_listener"
require "water_reader/fake_water_measurement_listener"
require "water_reader/water_measurement_parser"

require "database_connection_factory"
require "database_reader"

require "current_water_usage_store"
require "water_measurement_store"

Dotenv.load

def main
  environment = ENV.fetch('ENVIRONMENT')

  current_water_usage_store = CurrentWaterUsageStore.new
  water_measurement_store = WaterMeasurementStore.new(
    redis_host: ENV.fetch("REDIS_HOST"),
    redis_key: ENV.fetch("REDIS_WATER_COUNTER_NAME")
  )

  if environment == "production"
    last_water_measurement = get_last_water_measurement(environment)

    water_data_source = WaterReader::WaterMeasurementListener.new
  else
    puts "Fake water measurement reader"

    last_water_measurement = 0

    water_data_source = WaterReader::FakeWaterMeasurementListener.new
  end

  water_measurement_parser = WaterReader::WaterMeasurementParser.new(last_water_measurement)

  water_measurement_parser.on_tick = ->() {
    water_measurement_store.set(water_measurement_parser.last_measurement)

    current_water_usage_store.add_tick DateTime.now
  }

  loop do
    if water_data_source.ready?
      reading = water_data_source.read

      water_measurement_parser.parse(reading)
      puts water_measurement_parser.last_measurement
    end
  end
end

def get_last_water_measurement(environment)
  database_reader = DatabaseReader.new(DatabaseConnectionFactory.new(environment))

  database_reader.last_measurement.water
end

puts "Starting..."
main
