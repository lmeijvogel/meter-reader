require 'rubygems'
require 'sinatra'

$LOAD_PATH << "../lib"
$LOAD_PATH << "../models"

require_relative 'energie_api.rb'

map '/api' do
  run EnergieApi
end
