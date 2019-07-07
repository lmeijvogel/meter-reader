require 'rubygems'
require 'sinatra'
require 'logger'

$LOAD_PATH << "../lib"
$LOAD_PATH << "../models"

require_relative 'energie_api.rb'

set :logger, Logger.new(STDOUT)

run_static_site = ENV.fetch("RACK_ENV") != "production"

if run_static_site
  static_controller = Sinatra.new do
    REACT_BUILD_PATH = File.join(__dir__, "../../meter-reader-react/build")

    set :public_folder, REACT_BUILD_PATH

    get '/*' do
      File.read(File.join(REACT_BUILD_PATH, "index.html"))
    end
  end
end

map '/api' do
  run EnergieApi
end

if run_static_site
  map '/' do
    run Sinatra.new(static_controller)
  end
end
