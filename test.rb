require './app' #REVIEW: Why is the ./ needed?
require 'test/unit'
require 'rack/test'

ENV['RACK_ENV'] = 'test'

class DashTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Dash::App
  end

  def test_it_contains_the_word_dash
    get '/'
    assert last_response.body.include?('Dash')
  end

  def test_it_can_connect_to_google_analytics
    assert_equal false, Dash::App.settings.profile.nil?
  end

  def test_it_can_get_visits
    data = Dash::GraphData.new(Date.today .. Date.today)
    visits = data.visits('all')
    assert_equal false, visits.nil?
  end
end