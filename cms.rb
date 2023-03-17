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

# def render_file(file_path)
#   file = File.read(file_path)
# 
#   case File.extname(file_path)
#   when '.md'
#     @markdown.render(file)
#   when '.txt'
#     file
#   end
# end
# 
# def set_content_type(file_path)
#   case File.extname(file_path)
#   when '.md'
#     'text/html;charset=utf-8'
#   when '.txt'
#     'text/plain'
#   end
# end

def render_md(file_path)
  @markdown.render(File.read(file_path))
end

get '/' do
  erb :index, layout: :layout
end

get '/:filename' do
  filename = params[:filename]
  file_path = "#{@root_path}/public/data/#{filename}"
  
  if @files.include? filename
    # headers['Content-Type'] = set_content_type(file_path)
    # @file = render_file(file_path)

    case File.extname(file_path)
    when '.md'
      render_md(file_path)
    when '.txt'
      headers['Content-Type'] = 'text/plain'
      File.read(file_path)
    end
  else
    session[:error] = "#{filename} does not exist."
    redirect '/'
  end
end
