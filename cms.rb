require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'

before do
  @root_dir = File.expand_path('..', __FILE__)
end

get '/' do
  @root_dir = File.expand_path('..', __FILE__)
  @files = Dir['*', base: "#{@root_dir}/public/data"]
  erb :index, layout: :layout
end

get '/:file' do
  filename = params[:file]
  # @file = File.read("/data/#{filename}")

  @file = File.readlines("#{@root_dir}/public/data/#{filename}")

  erb :file, layout: :layout
end
