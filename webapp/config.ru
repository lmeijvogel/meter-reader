require 'rubygems'
require 'sinatra'

require_relative 'energie.rb'
require_relative 'energie_api.rb'

map '/energie' do
  run Energie
end

map '/energie-api' do
  run EnergieApi
end
