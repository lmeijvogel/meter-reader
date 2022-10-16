require 'date'
require 'pathname'
require 'time' # Time.strptime creates a date in the current timezone, but strptime is only available when requiring 'Time'
require 'json'
require 'dotenv'

$LOAD_PATH << File.expand_path("./lib")

require "output/influxdb_client"
require "solar_edge_client"

# Used by DatabaseConfig
ROOT_PATH = Pathname.new File.dirname(__FILE__)

Dotenv.load

def main
  one_week_in_seconds = 7 * 24 * 60 * 60
  one_week_ago = Time.now - one_week_in_seconds

  query_start = one_week_ago

  solar_edge_client = SolarEdgeClient.new(ENV.fetch("SOLAR_EDGE_SITE_ID"), ENV.fetch("SOLAR_EDGE_API_KEY"))

  json = solar_edge_client.energy(query_start, Time.now)

  production_raw = JSON.parse(json).dig("energyDetails", "meters").find {|m| m["type"] == "Production" }.fetch("values");

  influx = InfluxDBClient.new(hostname: ENV.fetch("INFLUXDB_HOST"), org: ENV.fetch("INFLUXDB_ORG"), bucket: ENV.fetch("INFLUXDB_BUCKET"), token: ENV.fetch("INFLUXDB_TOKEN"))

  # Replace dates with parsed dates
  production = production_raw.map {|entry| entry.merge({"date" => Time.strptime(entry["date"], "%Y-%m-%d %H:%M:%S") } ) }

  puts "Received #{production_raw.size} from SolarEdge"

  production.each do |entry|
    influx.send_opwekking_reading(entry["value"], entry["date"])
  end
end

main
