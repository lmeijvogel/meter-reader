require 'rubygems'
require 'sinatra'

$LOAD_PATH << "../lib"
$LOAD_PATH << "../models"

require_relative 'energie_api.rb'

map '/energie-api' do
  run EnergieApi
end
