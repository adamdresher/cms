require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require 'redcarpet'

configure do
  enable :sessions
  set :session_secret, 'secret'
end

def data_path
  if ENV['RACK_ENV'] == 'test'
    File.expand_path('../test/data', __FILE__)
  else
    File.expand_path('../public/data', __FILE__)
  end
end

def render_md(file_path)
  @markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  @markdown.render(File.read(file_path))
end


def load_file_content(file_path)
  case File.extname(file_path)
  when '.md'
    render_md(file_path)
  when '.txt'
    headers['Content-Type'] = 'text/plain'
    File.read(file_path)
  end
end

get '/' do
  @files = Dir['*', base: data_path]

  erb :index, layout: :layout
end

get '/:filename' do
  filename = params[:filename]
  file_path = File.join(data_path, filename)
  
  if File.exists?(file_path)
    load_file_content(file_path)
  else
    session[:message] = "#{filename} does not exist."
    redirect '/'
  end
end

get '/:filename/edit' do
  @filename = params[:filename]
  @file_path = File.join(data_path, @filename)
  @file = File.read(@file_path)

  erb :edit_file, layout: :layout
end

post '/:filename/edit' do
  filename = params[:filename]
  file_path = File.join(data_path, filename)
  edited_content = params[:edited_content]

  File.write(file_path, edited_content)
  session[:message] = "#{filename} has been updated."

  redirect '/'
end
