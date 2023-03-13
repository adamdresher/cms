require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'

get '/' do
  @root_dir = File.expand_path('..', __FILE__)
  @files = Dir['*', base: "#{@root_dir}/public/data"]
  erb :index
end
