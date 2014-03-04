require_relative 'lib/database_reader.rb'

require 'json'
require 'yaml'
require 'mysql2'
require 'trollop'

opts = Trollop::options do
  opt :env, "Environment", default: "development"
end

config = YAML.load(File.read("database.yml"))[opts[:env]]
database_connection = Mysql2::Client.new(host: config["host"],
                                               database: config["database"],
                                               username: config["username"],
                                               password: config["password"])

puts DatabaseReader.new(database_connection).read().to_json
