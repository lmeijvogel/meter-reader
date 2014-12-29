require 'sinatra'
require 'erb'

require 'mysql2'
require 'json'
require 'pathname'
require 'fileutils'
require 'connection_pool'
require 'bcrypt'
require 'redis'

require 'digest/sha1'

require_relative '../lib/database_config.rb'
require_relative '../lib/database_reader.rb'

NoPasswordsFile = Class.new(StandardError)
UsernameNotFound = Class.new(StandardError)

ROOT_PATH = Pathname.new(File.join(File.dirname(__FILE__), "..")).realpath

set :bind, '0.0.0.0'

FileUtils.mkdir_p(ROOT_PATH.join("tmp/cache"))

$database = ConnectionPool.new(size: 2) do
  Mysql2::Client.new(DatabaseConfig.for(settings.environment))
end

class Energie < Sinatra::Base
  configure do
    # Storing login information in cookies is good enough for our purposes
    one_year = 60*60*24*365
    secret = File.read('session_secret.txt')
    use Rack::Session::Cookie, :expire_after => one_year, :secret => secret
    set :protection, :origin_whitelist => ['https://energie.maybird.nl']

    set :static, false
  end

  before do
    check_login_or_redirect unless request.path.include?("login")
  end

  get "/assets/*" do
    requested_path = params[:splat]

    full_path = ROOT_PATH.join("webapp", "public", "assets", *requested_path)

    if !File.exists?(full_path) || path_outside_webapp(full_path.realpath)
      halt 404 and return
    end

    cache_control :public, max_age: 3600

    etag Digest::SHA1.file(full_path)
    send_file full_path
  end

  get "/index.html" do
    render_template("index.html.erb")
  end

  get "/login.html" do
    render_template("login.html.erb")
  end

  get "/day/today" do
    $database.with {|database_connection|
      database_reader = DatabaseReader.new(database_connection)

      database_reader.day = :today

      database_reader.read().to_json
    }
  end

  get "/day/:year/:month/:day" do
    day = DateTime.new(params[:year].to_i, params[:month].to_i, params[:day].to_i)

    cached(:day, day) do
      $database.with {|database_connection|
        database_reader = DatabaseReader.new(database_connection)

        database_reader.day = day

        database_reader.read().to_json
      }
    end
  end

  get "/week/:year/:month/:day" do
    database_reader = DatabaseReader.new(database_connection)

    database_reader.week = DateTime.new(params[:year].to_i, params[:month].to_i, params[:day].to_i)

    database_reader.read().to_json
  end

  get "/month/:year/:month" do
    $database.with {|database_connection|
      database_reader = DatabaseReader.new(database_connection)

      database_reader.month = DateTime.new(params[:year].to_i, params[:month].to_i)

      database_reader.read().to_json
    }
  end

  get "/energy/current" do
    result = JSON.parse(Redis.new.get("measurement"))

    @id = result["id"];
    @current_measurement = result["stroom_current"]

    { id: @id, current: @current_measurement }.to_json
  end

  get "/" do
    redirect to("index.html")
  end

  def cached(prefix, date)
    cache_file = ROOT_PATH.join("tmp", "cache", "#{prefix}_#{date.year}_#{date.month}_#{date.day}")

    if date < Date.today
      if File.exist?(cache_file)
        File.read(cache_file)
      else
        contents = yield
        File.open(cache_file, "w") do |file|
          file.write contents
        end
        contents
      end
    else
      yield
    end
  end

  post "/login/create" do
    username = params["username"]
    password = params["password"]

    begin
      stored_password_hash = read_password_hash(username)

      password_valid = BCrypt::Password.new(stored_password_hash) == password
      if password_valid
        session.clear
        session[:username] = username

        redirect(url("/", false))
      else
        invalid_username_or_password!
      end
    rescue UsernameNotFound, BCrypt::Errors::InvalidHash
      invalid_username_or_password!
    rescue NoPasswordsFile
      status 401
      "No passwords file"
    end
  end

  def read_password_hash(username)
    raise NoPasswordsFile unless File.exists? "passwords"

    password_hashes = YAML.load(File.read("passwords"))

    password_hashes.fetch(username) { raise UsernameNotFound }
  end

  def invalid_username_or_password!
    status 401
    "Invalid username or password"
  end

  def check_login_or_redirect
    if session[:username].nil?
      redirect url("login.html", false)
    else
      pass
    end
  end

  def render_template(template_name)
    template = File.read(File.join(templates_path, template_name))
    ERB.new(template).result(binding)
  end

  def templates_path
    @_templates_path ||= File.join(File.dirname(__FILE__), "templates")
  end

  def path_outside_webapp(path)
    webapp_path = ROOT_PATH.join("webapp")

    path.enum_for(:ascend).none? {|p| p == webapp_path }
  end
end
