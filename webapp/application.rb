require 'sinatra'
require 'mysql2'
require 'json'

require_relative '../lib/database_config.rb'
require_relative '../lib/database_reader.rb'

set :bind, '0.0.0.0'

database_connection = Mysql2::Client.new(DatabaseConfig.for(settings.environment))

get "/day/today" do
  database_reader = DatabaseReader.new(database_connection)

  database_reader.day = :today

  database_reader.read().to_json
end

get "/day/:year/:month/:day" do
  database_reader = DatabaseReader.new(database_connection)

  database_reader.day = DateTime.new(params[:year].to_i, params[:month].to_i, params[:day].to_i)

  database_reader.read().to_json
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
