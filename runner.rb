require 'pathname'
require 'serialport'
require 'mysql2'
require 'dotenv'

$LOAD_PATH << "lib"
$LOAD_PATH << "models"
require "measurement_parser"
require "data_parsing/stream_splitter"
require "data_parsing/fake_stream_splitter"
require "output/database_writer"
require "output/last_measurement_store"
require "database_config"
require "recorder"

ROOT_PATH = Pathname.new File.dirname(__FILE__)

Dotenv.load

recorder = Recorder.new(ENV.fetch('ENVIRONMENT'))
recorder.collect_data
