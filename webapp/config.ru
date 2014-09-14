require 'rubygems'
require 'sinatra'

require_relative 'energie.rb'

map '/energie' do
  run Energie
end
