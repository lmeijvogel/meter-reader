source 'https://rubygems.org'

gem "mysql2"
gem "bcrypt"

gem "sinatra"
gem 'thin'
gem 'connection_pool'
gem 'redis'
gem 'dotenv'
gem 'serialport'

# The docs say that the gem should not be added to the Gemfile, but I don't want to install
# it separately in development and production
gem 'foreman'
gem 'foreman-export-initscript', github: "metaquark/foreman-export-initscript"

group :development do

  gem "guard"
  gem "guard-rspec"
  gem "timecop"
  gem "rspec"
end
