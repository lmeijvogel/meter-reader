require 'yaml'

class DatabaseConfig
  class NoConfigFound < StandardError ; end

  def self.for(environment)
    config = YAML.load(File.read("database.yml"))[environment.to_s]

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
end
