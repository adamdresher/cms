require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require 'redcarpet'

$EXTENSIONS = ['.txt', '.md']
configure do
  enable :sessions
  set :session_secret, 'secret'
  set :show_exceptions, :after_handler
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

def file_extension_exists?(filename)
  $EXTENSIONS.any? { |ext| File.extname(filename) == ext }
end

def load_file_content(file_path)
  case File.extname(file_path)
  when '.md'
    erb render_md(file_path)
  when '.txt'
    headers['Content-Type'] = 'text/plain'
    File.read(file_path)
  end
end

get '/' do
  @files = Dir['*', base: data_path]
  @user = session[:user]

  if @user
    erb :index
  else
    redirect '/users/signin'
  end
end

get '/new_doc' do
  erb :new_doc
end

post '/new_doc' do
  filename = params[:filename]

  if file_extension_exists?(filename)
    File.new(File.join(data_path, filename), 'w')
    session[:message] = "#{filename} was created."
    redirect '/'
  elsif filename.strip.empty?
      session[:message] = "A name is required."
  else
    session[:message] = "The name must end with a valid file extension ('.md' or '.txt')."
  end

  status 422
  erb :new_doc
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

  erb :edit_file
end

post '/:filename/edit' do
  filename = params[:filename]
  file_path = File.join(data_path, filename)
  edited_content = params[:edited_content]

  File.write(file_path, edited_content)
  session[:message] = "#{filename} has been updated."

  redirect '/'
end

post '/:filename/delete' do
  filename = params[:filename]
  File.delete(File.join(data_path, filename))

  session[:message] = "#{filename} has been deleted."
  redirect '/'
end

get '/users/signin' do
  erb :signin
end

post '/users/signin' do
  username = params[:username]
  password = params[:password]
  session[:user] = username

  if username == 'admin' && password == 'secret'
    session[:message] = 'Welcome!'
    redirect '/'
  else
    session[:message] = 'Invalid credentials.'
    status 422
    erb :signin
  end
end

post '/users/signout' do
  session.delete(:user)
  session[:message] = 'You have signed out.'
  redirect '/users/signin'
end

# not_found do
#   redirect '/'
# end

# error 422 do
#   # '422 boom!'
#   redirect '/'
# end
