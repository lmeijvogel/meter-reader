source 'https://rubygems.org'

gem "mysql2"
gem "bcrypt"

gem "sinatra"
gem 'thin'
gem 'dotenv'
gem 'serialport'

# The docs say that the gem should not be added to the Gemfile, but I don't want to install
# it separately in development and production
gem 'foreman'
gem 'foreman-export-initscript', git: "git@github.com:metaquark/foreman-export-initscript"

gem "p1_meter_reader"
group :development do
  gem "guard"
  gem "guard-rspec"
  gem "timecop"
  gem "rspec"
end
