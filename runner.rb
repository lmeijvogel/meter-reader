require 'pathname'
require 'serialport'
require 'mysql2'
require 'dotenv'

require_relative "models/meterstand.rb"
require_relative "lib/data_parsing/stream_splitter.rb"
require_relative "lib/output/database_writer.rb"
require_relative "lib/output/redis_writer.rb"
require_relative "lib/database_config.rb"
require_relative "lib/recorder.rb"

ROOT_PATH = Pathname.new File.dirname(__FILE__)

Dotenv.load

recorder = MeterstandenRecorder.new(ENV['ENVIRONMENT'])
recorder.collect_data
