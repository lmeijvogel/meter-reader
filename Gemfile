source "https://rubygems.org"

# Can't compile bcrypt 3.1.13 on Raspberry Pi?
gem "bcrypt", "=3.1.12"
gem "dotenv"
gem "mysql2"
gem "p1_meter_reader", git: "https://github.com/lmeijvogel/p1_meter_reader_gem", branch: "report_water_usage"
gem "serialport"
gem "sinatra", ">= 2.0.5"
gem "thin"
gem "redis"

group :development do
  gem "byebug"
  gem "guard"
  gem "guard-rspec"
  gem "rspec"
  gem "sinatra-contrib"
  gem "timecop"
end
