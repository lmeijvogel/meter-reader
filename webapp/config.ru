require 'rubygems'
require 'sinatra'

$LOAD_PATH << "../lib"
$LOAD_PATH << "../models"

require_relative 'energie_api.rb'

run_static_site = ENV.fetch("RACK_ENV") != "production"

if run_static_site
  static_controller = Sinatra.new do
    ELM_BUILD_PATH = File.dirname(__FILE__) + '/../../elm/out'

    set :public_folder, ELM_BUILD_PATH

    get '/' do
      File.read(File.join(ELM_BUILD_PATH, "index.html"))
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
