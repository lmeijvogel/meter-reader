require 'rubygems'
require 'sinatra'

$LOAD_PATH << "../lib"
$LOAD_PATH << "../models"

require_relative 'energie_api.rb'

static_controller = Sinatra.new do
  REACT_BUILD_PATH = File.dirname(__FILE__) + '/../../react/build'
  puts File.realpath(REACT_BUILD_PATH)
  set :public_folder, REACT_BUILD_PATH

  Dir.glob("#{REACT_BUILD_PATH}/*").each do |file|
    puts file
  end

  get '/' do
    File.read(File.join(REACT_BUILD_PATH, "index.html"))
  end

end
map '/api' do
  run EnergieApi
end

map '/' do
  run Sinatra.new(static_controller)
end
