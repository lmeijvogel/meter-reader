require 'sinatra'
require 'mysql2'
require 'json'
require 'pathname'
require 'fileutils'

require_relative '../lib/database_config.rb'
require_relative '../lib/database_reader.rb'

ROOT_PATH = Pathname.new(File.join(File.dirname(__FILE__), ".."))

set :bind, '0.0.0.0'

FileUtils.mkdir_p(ROOT_PATH.join("tmp/cache"))

database_connection = Mysql2::Client.new(DatabaseConfig.for(settings.environment))

get "/day/today" do
  database_reader = DatabaseReader.new(database_connection)

  database_reader.day = :today

  database_reader.read().to_json
end

get "/day/:year/:month/:day" do
  day = DateTime.new(params[:year].to_i, params[:month].to_i, params[:day].to_i)

  cached(:day, day) do
    database_reader = DatabaseReader.new(database_connection)

    database_reader.day = day

    database_reader.read().to_json
  end
end

get "/week/:year/:month/:day" do
  database_reader = DatabaseReader.new(database_connection)

  database_reader.week = DateTime.new(params[:year].to_i, params[:month].to_i, params[:day].to_i)

  database_reader.read().to_json
end

get "/month/:year/:month" do
  database_reader = DatabaseReader.new(database_connection)

  database_reader.month = DateTime.new(params[:year].to_i, params[:month].to_i)

  database_reader.read().to_json
end

get "/energy/current" do
  results = database_connection.query("SELECT stroom_current FROM measurements ORDER BY id DESC LIMIT 1")

  @current_measurement = results.first["stroom_current"]

  { current: @current_measurement }.to_json
end

get "/" do
  redirect to("index.html")
end

def cached(prefix, date)
  cache_file = ROOT_PATH.join("tmp", "cache", "#{prefix}_#{date.year}_#{date.month}_#{date.day}")

  if date < Date.today
    if File.exist?(cache_file)
      File.read(cache_file)
    else
      contents = yield
      File.open(cache_file, "w") do |file|
        file.write contents
      end
      contents
    end
  else
    yield
  end
end
