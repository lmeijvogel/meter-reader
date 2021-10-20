require 'sinatra/base'

require 'mysql2'
require 'json'
require 'pathname'
require 'fileutils'
require 'bcrypt'
require 'dotenv'

require 'digest/sha1'

$LOAD_PATH << "../lib"
$LOAD_PATH << "../models"

require 'database_config'
require 'database_reader'
require 'recent_measurement_store'
require 'water_measurement_store'
require 'current_water_usage_calculator'

require 'webapp/results_cache'
require 'webapp/day_cache_descriptor'
require 'webapp/month_cache_descriptor'
require 'webapp/year_cache_descriptor'

ROOT_PATH = Pathname.new(File.join(File.dirname(__FILE__), "..")).realpath

Dotenv.load

$enable_cache = true

class DatabaseConnectionFactory
  def initialize(database_config)
    @database_config = database_config
  end

  def with_connection
    connection = Mysql2::Client.new(@database_config)

    yield connection
  rescue Exception => e
    puts "Exception while opening database:"
    puts e.inspect
  ensure
    connection.close
  end
end

class EnergieApi < Sinatra::Base
  database_config = DatabaseConfig.for(settings.environment)
  connection_factory = DatabaseConnectionFactory.new(database_config)
  recent_measurement_store = RecentMeasurementStore.new(
    number_of_entries: 6 * 60 * 4,
    redis_host: ENV.fetch("REDIS_HOST"),
    redis_list_name: ENV.fetch("REDIS_MEASUREMENTS_LIST_NAME")
  )

  water_measurement_store = WaterMeasurementStore.new(
    redis_host: ENV.fetch("REDIS_HOST")
  )


  configure :development do
    require 'sinatra/reloader'
    register Sinatra::Reloader
    also_reload File.expand_path("../lib/*")

    $enable_cache = false
  end

  configure do
    # Storing login information in cookies is good enough for our purposes
    one_year = 60*60*24*365
    secret = ENV.fetch('SESSION_SECRET')
    use Rack::Session::Cookie, :expire_after => one_year, :secret => secret

    set :static, false

    set :bind, '0.0.0.0'
    set :port, 9292

    FileUtils.mkdir_p(ROOT_PATH.join("tmp/cache"))
  end

  get "/api/" do
    status 204
  end

  get "/api/day/:year/:month/:day.json" do
    day = DateTime.new(Integer(params[:year], 10), Integer(params[:month], 10), Integer(params[:day], 10))

    cached(:day, day) do
      database_reader = DatabaseReader.new(connection_factory)

      database_reader.read_for_day(day).to_json
    end
  end

  get "/api/month/:year/:month.json" do
    month = DateTime.new(Integer(params[:year], 10), Integer(params[:month], 10), 1)

    cached(:month, month) do
      database_reader = DatabaseReader.new(connection_factory)

      database_reader.read_for_month(month).to_json
    end
  end

  get "/api/year/:year.json" do
    year = DateTime.new(Integer(params[:year], 10), 1, 1)

    cached(:year, year) do
      database_reader = DatabaseReader.new(connection_factory)

      database_reader.read_for_year(year).to_json
    end
  end

  get "/api/energy/current" do
    recent_measurements = recent_measurement_store.measurements

    if recent_measurements.none?
      status 404
      "Not found"
      break
    end

    result = JSON.parse(recent_measurements.last)

    last_water_ticks_redis = water_measurement_store.ticks
    last_water_ticks = last_water_ticks_redis.map { |str| DateTime.parse(str) }

    water_current = CurrentWaterUsageCalculator.calculate(last_water_ticks)

    { id: result["id"],
      current: result["stroom_current"],
      gas: result["gas"],
      water: result["water"],
      water_current: water_current,
    }.to_json
  end

  get "/api/energy/recent" do
    "[" +
      recent_measurement_store.measurements.join(", ") +
      "]"
  end

  def cached(prefix, date)
    if !$enable_cache
      return yield
    end

    cache_dir = ROOT_PATH.join("tmp", "cache")

    cache_descriptor = case prefix
    when :year
      YearCacheDescriptor.new(date, cache_dir)
    when :month
      MonthCacheDescriptor.new(date, cache_dir)
    when :day
      DayCacheDescriptor.new(date, cache_dir)
    end

    ResultsCache.new(date, descriptor: cache_descriptor).cached do
      yield
    end
  end

  def production?
    ENV.fetch("RACK_ENV") == "production"
  end

  run! if app_file == $0
end
