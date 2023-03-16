require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require 'redcarpet'

configure do
  enable :sessions
  set :session_secret, 'secret'
end

before do
  @root_path = File.expand_path('..', __FILE__)
  @files = Dir['*', base: "#{@root_path}/public/data"]
  @markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
end

get '/' do
  erb :index, layout: :layout
end

get '/:filename' do
  filename = params[:filename]
  
  if @files.include? filename
    @file = File.read("#{@root_path}/public/data/#{filename}")
    if File.extname("#{@root_path}/public/data/#{filename}") == '.md'
      @file = @markdown.render(@file)
    else
      headers['Content-Type'] = 'text/plain'
      @file
    end
  else
    session[:error] = "#{filename} does not exist."
    redirect '/'
  end
  # erb :file, layout: :layout
end
