require 'sinatra'

require 'mysql2'
require 'json'
require 'pathname'
require 'fileutils'
require 'bcrypt'
require 'dotenv'

require 'digest/sha1'

require 'database_config'
require 'database_reader'
require 'recent_measurement_store'
require 'current_water_usage_store'

require 'webapp/results_cache'
require 'webapp/day_cache_descriptor'
require 'webapp/month_cache_descriptor'
require 'webapp/year_cache_descriptor'

NoPasswordsFile = Class.new(StandardError)
UsernameNotFound = Class.new(StandardError)

ROOT_PATH = Pathname.new(File.join(File.dirname(__FILE__), "..")).realpath
Dotenv.load

require 'sinatra/reloader' if development?

set :bind, '0.0.0.0'
set :port, 8000

FileUtils.mkdir_p(ROOT_PATH.join("tmp/cache"))

class DatabaseConnectionFactory
  def initialize(database_config)
    @database_config = database_config
  end

  def with_connection
    connection = Mysql2::Client.new(@database_config)

    yield connection
  ensure
    connection.close
  end
end

class EnergieApi < Sinatra::Base
  database_config = DatabaseConfig.for(settings.environment)
  connection_factory = DatabaseConnectionFactory.new(database_config)
  recent_measurement_store = RecentMeasurementStore.new(
    number_of_entries: 6 * 60 * 4,
    redis_list_name: ENV.fetch("REDIS_LIST_NAME")
  )

  current_water_usage_store = CurrentWaterUsageStore.new

  configure do
    # Storing login information in cookies is good enough for our purposes
    one_year = 60*60*24*365
    secret = ENV.fetch('SESSION_SECRET')
    use Rack::Session::Cookie, :expire_after => one_year, :secret => secret

    set :static, false
  end

  before do
    assert_logged_in unless request.path.include?("login")
  end

  get "/" do
    status 204
  end

  get "/day/:year/:month/:day" do
    day = DateTime.new(params[:year].to_i, params[:month].to_i, params[:day].to_i)

    cached(:day, day) do
      database_reader = DatabaseReader.new(connection_factory)

      database_reader.day = day

      database_reader.read().to_json
    end
  end

  get "/month/:year/:month" do
    month = DateTime.new(params[:year].to_i, params[:month].to_i, 1)

    cached(:month, month) do
      database_reader = DatabaseReader.new(connection_factory)

      database_reader.month = DateTime.new(params[:year].to_i, params[:month].to_i)

      database_reader.read().to_json
    end
  end

  get "/year/:year" do
    year = DateTime.new(params[:year].to_i, 1, 1)

    cached(:year, year) do
      database_reader = DatabaseReader.new(connection_factory)

      database_reader.year = DateTime.new(params[:year].to_i)

      database_reader.read().to_json
    end
  end

  get "/energy/current" do
    recent_measurements = recent_measurement_store.measurements

    if recent_measurements.none?
      status 404
      "Not found"
      break
    end

    result = JSON.parse(recent_measurements.last)

    water_current = current_water_usage_store.usage


    { id: result["id"],
      current: result["stroom_current"],
      gas: result["gas"],
      water: result["water"],
      water_current: water_current,
      water_current_period_in_seconds: current_water_usage_store.period_in_seconds
    }.to_json
  end

  get "/energy/recent" do
    "[" +
      recent_measurement_store.measurements.join(", ") +
      "]"
  end

  def cached(prefix, date)
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

  post "/login/create" do
    username = params["username"]
    password = params["password"]

    begin
      stored_password_hash = read_password_hash(username)

      password_valid = BCrypt::Password.new(stored_password_hash) == password
      if password_valid
        session.clear
        session[:username] = username

        status 200
        "Welcome!"
      else
        invalid_username_or_password!
      end
    rescue UsernameNotFound, BCrypt::Errors::InvalidHash
      invalid_username_or_password!
    rescue NoPasswordsFile
      halt 401, "No passwords file"
    end
  end

  def read_password_hash(username)
    raise NoPasswordsFile unless File.exists? "passwords"

    password_hashes = YAML.load(File.read("passwords"))

    password_hashes.fetch(username) { raise UsernameNotFound }
  end

  def invalid_username_or_password!
    halt 401, "Invalid username or password"
  end

  def assert_logged_in
    if session[:username].nil?
      halt 401, "Not logged in"
    else
      pass
    end
  end

  def production?
    ENV.fetch("RACK_ENV") == "production"
  end
end
