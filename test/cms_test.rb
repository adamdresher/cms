# frozen_string_literal: true

ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'rack/test'
require 'fileutils'

require_relative '../cms'

class CMSTest < Minitest::Test
  include Rack::Test::Methods

  def setup
    FileUtils.mkdir_p(data_path)
  end

  def teardown
    FileUtils.rm_rf(data_path)
  end

  def create_document(name, content='')
    File.open(File.join(data_path, name), 'w') do |file|
      file.write(content)
    end
  end

  def app
    Sinatra::Application
  end

  def test_index
    create_document 'about.txt'
    create_document 'quotes.md'

    get '/'

    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, 'about.txt'
    assert_includes last_response.body, 'quotes.md'
  end

  def test_viewing_text_file
    create_document 'history.txt', "1993 - Yukihiro Matsumoto dreams up Ruby."

    get '/history.txt'

    assert_equal 200, last_response.status
    assert_equal 'text/plain', last_response['Content-Type']
    assert_includes last_response.body, "Yukihiro Matsumoto dreams up Ruby."
  end

  def test_viewing_md_file
    create_document 'quotes.md', "We are what we repeatedly do.  Excellence, then, is not an act, but a habit."

    get '/quotes.md'

    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, 'We are what we repeatedly do.'
  end

  def test_viewing_nonexistent_file
    create_document 'about.txt'

    get '/nonexistent_file.txt'

    refute_path_exists File.join(data_path, 'nonexistent_file.txt')
    assert_equal 302, last_response.status

    get last_response['Location']

    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, 'nonexistent_file.txt does not exist.'
    assert_includes last_response.body, 'about.txt'

    get '/'

    assert_equal 200, last_response.status
    refute_includes last_response.body, 'nonexistent_file.txt does not exist.'
    assert_includes last_response.body, 'about.txt'
  end

  def test_editing_file_form
    create_document 'quotes.md'

    get '/quotes.md/edit'

    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, "<textarea"
    assert_includes last_response.body, %Q(<button form="content" type="submit")
  end

  def test_editing_file_submit
    create_document 'quotes.md'
    create_document 'about.txt'

    post '/quotes.md/edit', edited_content: 'new content'

    assert_equal 302, last_response.status

    get last_response['Location']

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'quotes.md has been updated.'
    assert_includes last_response.body, %q(quotes.md</a>)
    assert_includes last_response.body, 'about.txt'

    get '/'

    assert_equal 200, last_response.status
    refute_includes last_response.body, 'quotes.md has been updated.'

    get '/quotes.md'

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'new content'
  end
end

def test_viewing_new_file_form
  get '/new_doc'

  assert_equal 200, last_response.status
  assert_includes 'Add a new document', last_response.body
  assert_includes last_response.body, '<input'
  assert_includes last_response.body, %q(<button form="submit")
end

def test_submiting_new_file
  post '/new_doc', filename: 'new_file.txt'

  assert_equal 303, last_response.status

  get last_response['Location']

  assert_equal 200, last_response.status
  assert_includes last_response.body, 'new_file.txt has been created.'
  assert_includes last_response.body, %q(new_file.txt</a>)
  assert_includes last_response.body, 'quotes.md'

  get '/'

  refute_includes last_response.body, 'new_file.txt has been created.'
  assert_includes last_response.body, %q(new_file.txt</a>)
end

def test_submitting_new_file_without_name
  post '/new_doc', filename: ''

  assert_equal 422, last_response.status
  assert_includes last_response.body, 'A name is required.'
end

def test_submitting_new_file_without_valid_extension
  post '/new_doc', filename: 'invalid.doc'

  assert_equal 422, last_response.status
  assert_includes last_response.body, "The name must end with a valid file extension ('.md' or '.txt')."
end
