#!/usr/bin/env ruby

require "highline"
require "bcrypt"
require "yaml"

cli = HighLine.new

user = cli.ask("Username?")
pass = cli.ask("Password?") { |c| c.echo = false }

puts "Adding user '#{user}'"

begin
  hashed_password = BCrypt::Password.create(pass)

  password_hashes = if File.exist?("passwords")
                      YAML.safe_load(File.read("passwords"))
                    else
                      {}
                    end

  password_hashes[user] = hashed_password.to_s

  File.open("passwords", "w") do |file|
    file.write password_hashes.to_yaml
  end

  puts "... done"
end

