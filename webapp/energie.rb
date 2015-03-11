require 'sinatra'

require 'pathname'
require 'digest/sha1'

ROOT_PATH = Pathname.new(File.join(File.dirname(__FILE__), "..")).realpath

set :bind, '0.0.0.0'

class Energie < Sinatra::Base
  configure do
    set :static, false
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

  get "/*" do
    send_file "index.html"
  end

  def path_outside_webapp(path)
    webapp_path = ROOT_PATH.join("webapp")

    path.enum_for(:ascend).none? {|p| p == webapp_path }
  end
end
