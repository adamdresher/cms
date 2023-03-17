# frozen_string_literal: true

ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'rack/test'

require_relative '../cms'

class CMSTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_index
    get '/'

    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, 'quotes.md'
    assert_includes last_response.body, 'about.txt'
    assert_includes last_response.body, 'changes.txt'
    assert_includes last_response.body, 'history.txt'

    # assert_includes edit links
  end

  def test_viewing_text_file
    get '/history.txt'

    assert_equal 200, last_response.status
    assert_equal 'text/plain', last_response['Content-Type']
    assert_includes last_response.body, 'Ruby 0.95 released.'
  end

  def test_viewing_md_file
    get '/quotes.md'

    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, 'Your past does not '
  end

  def test_nonexistent_file
    get '/nonexistent_file.txt'

    root_path = File.expand_path('..', __FILE__)
    refute_path_exists "#{root_path}/public/data/nonexistent_file.txt"
    assert_equal 302, last_response.status

    get last_response['Location']

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'nonexistent_file.txt does not exist.'
    assert_includes last_response.body, 'about.txt'

    get '/'

    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    refute_includes last_response.body, 'nonexistent_file.txt does not exist.'
    assert_includes last_response.body, 'about.txt'
  end

  def test_edit_file_form
    get '/quotes.md/edit'

    assert_equal 200, last_response.status
    assert_equal 'text/html;charset=utf-8', last_response['Content-Type']
    assert_includes last_response.body, "<textarea"
    assert_includes last_response.body, %q[<button type="submit"]
  end

  def test_edit_file
    one_more_quote = "*\"I'm like the drunk in the bar who wants just one more for the road.\"*<br>- Archie Moore"
    post '/quotes_dup.md/edit', edited_content: one_more_quote

    assert_equal 302, last_response.status

    get last_response['Location']

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'quotes_dup.md has been updated.'
    assert_includes last_response.body, 'about.txt'

    get '/quotes_dup.md'

    assert_equal 200, last_response.status
    refute_includes last_response.body, 'quotes_dup.md has been updated.'
    assert_includes last_response.body, 'just one more'
  end
end
