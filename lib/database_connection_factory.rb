require 'mysql2'
require 'database_config'

class DatabaseConnectionFactory
  def initialize(environment)
    @environment = environment
  end

  def with_connection
    with_retries(log_message_format: "Retrying SQL connection (%d/%d)") do
      connection = Mysql2::Client.new(DatabaseConfig.for(@environment))
      begin
        puts connection.inspect
        yield connection
      ensure
        connection.close
      end
    end
  end

  private

  def with_retries(max_tries: 5, log_message_format: "Retrying (%d/%d)")
    tries = 0

    retry_interval_in_seconds = 2

    begin
      yield
    rescue Mysql2::Error => e
      puts "Error: #{e.message}"
      tries += 1

      if tries > max_tries
        raise
      end

      puts format(log_message_format, tries, max_tries)
      sleep retry_interval_in_seconds

      retry_interval_in_seconds *= 2

      retry
    end
  end
end


