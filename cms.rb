require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require 'redcarpet'
require 'yaml'
require 'bcrypt'

$EXTENSIONS = ['.txt', '.md']

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :show_exceptions, :after_handler
  set :erb, :escape_html => true
end

def data_path
  if ENV['RACK_ENV'] == 'test'
    File.expand_path('../test/data', __FILE__)
  else
    File.expand_path('../public/data', __FILE__)
  end
end

def file_extension_exists?(filename)
  $EXTENSIONS.any? { |ext| File.extname(filename) == ext }
end

def load_file_content(file_path)
  content = File.read(file_path)

  case File.extname(file_path)
  when '.md'
    erb render_md(content)
  when '.txt'
    headers['Content-Type'] = 'text/plain'
    content
  end
end

def render_md(content)
  @markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  @markdown.render(content)
end

def credentials_path
  path = if ENV['RACK_ENV'] == 'test'
           File.expand_path('../public/test', __FILE__)
         else
           File.expand_path('../public', __FILE__)
         end

  File.join(path, 'user_db.yml')
end

def load_credentials
  YAML.load_file(credentials_path)
end

def valid_credentials?(username, password)
  credentials = load_credentials
  
  if credentials.key? username
    hash = BCrypt::Password.new(credentials[username])
    hash == password
  else
    false
  end
end

def signed_in?
  session[:user]
end

def permission_denied
  session[:message] = "You must be signed in to do that."
  redirect '/'
end

def user_exists?(user)
  credentials = load_credentials
  credentials[user]
end

def add_new_user!(user, password)
  user_db_path = credentials_path
  new_user = "#{user}: #{BCrypt::Password.create(password)}\n"

  user_db = File.open(user_db_path, mode: 'a')
  user_db.write(new_user)
  user_db.close
end

get '/' do
  @files = Dir['*', base: data_path]
  @user = session[:user]

  erb :index
end

get '/new_doc' do
  permission_denied unless signed_in?
  erb :new_doc
end

post '/new_doc' do
  permission_denied unless signed_in?

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
  permission_denied unless signed_in?

  @filename = params[:filename]
  @file_path = File.join(data_path, @filename)
  @file = File.read(@file_path)

  erb :edit_file
end

post '/:filename/edit' do
  permission_denied unless signed_in?

  filename = params[:filename]
  file_path = File.join(data_path, filename)
  edited_content = params[:edited_content]

  File.write(file_path, edited_content)
  session[:message] = "#{filename} has been updated."

  redirect '/'
end

post '/:filename/delete' do
  permission_denied unless signed_in?

  filename = params[:filename]
  File.delete(File.join(data_path, filename))

  session[:message] = "#{filename} has been deleted."
  redirect '/'
end

post '/:filename/duplicate' do
  permission_denied unless signed_in?

  files = Dir['*', base: data_path]
  filename = params[:filename]
  file_path = File.join(data_path, filename)
  contents = File.read(file_path)

  dup_filename = filename.sub('.', '_copy.')
  num = 1 # skips adding a number to first copy

  while files.include? dup_filename
    num += 1
    dup_filename = filename.sub('.', "_copy#{num}.")
  end

  dup_file_path = File.join(data_path, dup_filename)
  File.new(dup_file_path, 'w')
  File.write(dup_file_path, contents)

  session[:message] = "#{dup_filename} was created."
  redirect '/'
end

get '/users/signin' do
  session.delete(:potential_user) # start fresh
  erb :signin
end

post '/users/signin' do
  session[:potential_user] = params[:username]

  if valid_credentials?(session[:potential_user], params[:password])
    session[:user] = session[:potential_user]
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
  redirect '/'
end

get '/users/new' do
  session.delete(:new_user) # start fresh
  erb :new_user
end

post '/users/new' do
  user = params[:new_user].strip
  session[:new_user] = user
  password = [params[:new_password1], params[:new_password2]]

  if user_exists?(user)
    session[:message] = "'#{user}' is taken, try something different."
  elsif user.strip.empty?
    session[:message] = "Please enter a username."
  elsif password.all? { |word| word.strip.empty? }
    session[:message] = "Please enter a password."
  elsif password.first != password.last
    session[:message] = "Your passwords did not match.  Please try again."
  else
    add_new_user!(session.delete(:new_user), password.first)
    session[:message] = "Your account has been created."
    redirect '/'
  end

  erb :new_user
end
