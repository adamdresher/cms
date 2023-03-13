require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'

get '/' do
  @root_dir = File.expand_path('..', __FILE__)
  @files = Dir['*', base: "#{@dir}/public/files"]
  erb :index
end
