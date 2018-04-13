require 'erb'
require 'yaml'

class DatabaseConfig
  class NoConfigFound < StandardError ; end

  def self.for(environment)
    config = YAML.load(database_config)[environment.to_s]

    if config.nil?
      raise NoConfigFound, "No config found for environment '#{environment}'"
    end

    { host: config["host"],
      database: config["database"],
      username: config["username"],
      password: config["password"],
      reconnect: true
    }
  end

  def self.database_config
    erb_content = File.read(ROOT_PATH.join("database.yml"))

    ERB.new(erb_content).result
  end
end
