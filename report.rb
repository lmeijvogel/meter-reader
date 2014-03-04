require_relative 'lib/database_reader.rb'
require_relative 'lib/database_config.rb'

require 'json'
require 'mysql2'
require 'trollop'

opts = Trollop::options do
  opt :env, "Environment", default: "development"
end

database_connection = Mysql2::Client.new(DatabaseConfig.for(opts[:env]))

puts DatabaseReader.new(database_connection).read().to_json
