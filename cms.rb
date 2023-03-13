require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'

before do
  @root_dir = File.expand_path('..', __FILE__)
end

get '/' do
  @files = Dir['*', base: "#{@root_dir}/public/data"]
  erb :index, layout: :layout
end

get '/:filename' do
  filename = params[:filename]
  @file = File.read("#{@root_dir}/public/data/#{filename}")

  headers['Content-Type'] = 'text/plain'
  @file
  # erb :file, layout: :layout
end
