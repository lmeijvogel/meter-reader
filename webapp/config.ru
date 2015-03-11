require 'rubygems'
require 'sinatra'

require_relative 'energie_api.rb'

map '/energie-api' do
  run EnergieApi
end
