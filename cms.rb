require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'

configure do
  enable :sessions
  set :session_secret, 'secret'
end

before do
  @root_path = File.expand_path('..', __FILE__)
  @files = Dir['*', base: "#{@root_path}/public/data"]
end

get '/' do
  erb :index, layout: :layout
end

get '/:filename' do
  filename = params[:filename]
  
  if @files.include? filename
    @file = File.read("#{@root_path}/public/data/#{filename}")

    headers['Content-Type'] = 'text/plain'
    @file
  else
    session[:error] = "#{filename} does not exist."
    redirect '/'
  end
  # erb :file, layout: :layout
end
