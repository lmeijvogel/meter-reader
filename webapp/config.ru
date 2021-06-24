require 'rubygems'
require 'logger'

$LOAD_PATH << "../lib"
$LOAD_PATH << "../models"
$LOAD_PATH << "."

require 'energie_api.rb'

puts "BOE"
# set :logger, Logger.new(STDOUT)
run EnergieApi.new
# map '/api' do
  # run ""#
# end

puts "BOE2"
