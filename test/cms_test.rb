ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'rack/test'

require_relative '../cms'

class CMSTest < Minitest::Test
  include Rack::Test::Methods

  def setup
    @root_dir = File.expand_path('../..', __FILE__)
    @files = Dir['*', base: "#{@root_dir}/public/data"]
  end

  def app
    Sinatra::Application
  end

  def test_index
    get '/'

    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    # assert_equal 
  end

  def test_filename_1
    skip
    get "/about.txt"

      file = File.read("#{@root_dir}/public/data/about.txt")

      assert_equal 200, last_response.status
      assert_equal 'text/plain', last_response['Content-Type']
      assert_equal file, last_response.body
    # end
  end

  def test_filename_2
    skip
    get "/changes.txt"

      file = File.read("#{@root_dir}/public/data/changes.txt")

      assert_equal 200, last_response.status
      assert_equal 'text/plain', last_response['Content-Type']
      assert_equal file, last_response.body
    # end
  end

  def test_filename_3
    skip
    get "/history.txt"

      file = File.read("#{@root_dir}/public/data/history.txt")

      assert_equal 200, last_response.status
      assert_equal 'text/plain', last_response['Content-Type']
      assert_equal file, last_response.body
    # end
  end

  def test_filename
    # filenames = ['about.txt', 'changes.txt', 'history.txt']
    # filenames.each do |filename|
    @files.each do |filename|
      get "/#{filename}"

      file = File.read("#{@root_dir}/public/data/#{filename}")

      assert_equal 200, last_response.status
      assert_equal 'text/plain', last_response['Content-Type']
      assert_equal file, last_response.body
    end
  end
end
