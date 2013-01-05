require 'rubygems'
require 'sinatra'
require 'sinatra/config_file'
require 'garb'
require 'data_mapper'
require 'rufus/scheduler'

#Set the access credentials for your GA account and the ID of the site in a config.yml file.
set :environment, :production, :development
config_file 'config.yml'

username   =  settings.username
password   =  settings.password
profile_id =  settings.profile_id

#Set the name of the brand. This is used to split out search traffic.
BRAND_NAME = 'smith'

#Set the currency of the store
CURRENCY = '&pound;'

#Some useful globals for the app.
TODAY     = Date.today
YESTERDAY = TODAY - 1
SDLW      = TODAY - 7

#Start the scheduler
scheduler = Rufus::Scheduler.start_new

#Connect to Google Analytics and find the correct site profile.
Garb::Session.login(username, password) # :secure => true
PROFILE = Garb::Management::Profile.all.detect {|p| p.web_property_id == profile_id}

#Define the metrics that garb, the Google Analytics gem, can access.
class All
  extend Garb::Model
  metrics :visits,
  :transaction_revenue,
  :transactions,
  :revenue_per_transaction
end

class Visits
  extend Garb::Model
  metrics :visits
end

#TODO - Goals

#Set up the database.
DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/development.db")

#Define the model for the data.
class Metric
  include DataMapper::Resource
  property :id,                       Serial
  property :source,                   String,   default: 'none'
  property :visits,                   Integer,  default: 0
  property :transaction_revenue,      Float,    default: 0
  property :transactions,             Integer,  default: 0
  property :revenue_per_transaction,  Float,    default: 0
  property :conversion_rate,          Float,    default: 0
  property :start_date,               Date,     default: TODAY
  property :end_date,                 Date,     default: TODAY
end

DataMapper.finalize.auto_upgrade!


#This method gets all the important GA data for a given date-range, and saves it to the database.
def all_metrics(start_date, end_date)
  d = PROFILE.all(start_date: start_date, end_date: end_date).first
  if d
    data = Metric.first_or_create(source:             'all',
      visits:                   d.visits.to_i,
      transaction_revenue:      d.transaction_revenue.to_f,
      transactions:             d.transactions.to_i,
      revenue_per_transaction:  d.revenue_per_transaction.to_f,
      conversion_rate:          (d.transactions.to_f / d.visits.to_f) * 100,
      start_date:               start_date,
      end_date:                 end_date)
  else
    data = Metric.first_or_create(start_date: start_date, end_date: end_date, source: source).update(visits: 0)
  end
  p data
end

#This method gets all the visits, separated by source, and saves them to the database.
def visits_by_source(start_date, end_date)
  #These represent the different traffic sources.
  traffic_sources = {'branded'   => { :medium.matches  => 'organic', :keyword.contains         => BRAND_NAME },
  'nonbranded' => { :medium.matches  => 'organic', :keyword.does_not_contain => "#{BRAND_NAME}" },
  'unknown'    => { :medium.matches  => 'organic', :keyword.contains         => '(not provided)|np|(not set)' },
  'affiliate'  => { :medium.matches  => 'affiliates'},
  'social'     => { :source.contains => "facebook\.com|twitter\.com|pinterest\.com" },
  'referral'   => { :medium.matches  => 'referral', :source.does_not_contain => "facebook\.com|twitter\.com|pinterest\.com" },
  'paid'       => { :medium.matches  => 'cpc' },
  'direct'     => { :source.matches  => '(direct)'},
  'email'      => { :medium.contains => "email|Email"}}

    #Make the requests to GA for the visits by source.
    traffic_sources.each do |source, filter|
      d = PROFILE.visits(start_date: start_date, end_date: end_date, filters: filter).first
      if d
      #Save the data.
      data = Metric.first_or_create(start_date: start_date, end_date: end_date, source: source).update(visits: d.visits.to_f)
    else
      #Save 0 if empty.
      data = Metric.first_or_create(start_date: start_date, end_date: end_date, source: source).update(visits: 0)
    end
    p data
  end
end

helpers do
  def visits(tag, date)
    check = Metric.last(start_date: date, end_date: date, source: tag)
    check.nil? ? 0 : check.visits
  end
end

#This is for the homepage of the dashboard. It gets all the necessary data from the database.
get '/' do
  #Data for the stacked area chart.
  #Defining the arrays for the area chart.
  @branded, @nonbranded, @unknown, @affiliate, @social, @referral, @paid, @direct, @email = [], [], [], [], [], [], [], [], []

  #Get the last 7 days of data.
  (SDLW...TODAY).each do |date|
    @branded    << visits('branded', date)
    @nonbranded << visits('nonbranded', date)
    @unknown    << visits('unknown', date)
    @affiliate  << visits('affiliate', date)
    @social     << visits('social', date)
    @referral   << visits('referral', date)
    @paid       << visits('paid', date)
    @direct     << visits('direct', date)
    @email      << visits('email', date)
  end

  #Days for the Y axis
  @days = (SDLW..TODAY).map{|date| date.strftime("%a").to_s}

  #Data for the small data panels.
  #TODO - How can I refactor this to clean up the code and catch errors more effectively?
  todays_data = Metric.last(source: 'all', start_date: TODAY, end_date: TODAY)
  @visits_today, @revenue_today, @checkouts_today, @basket_size_today, @conversion_rate_today = 0, 0, 0, 0, 0
  if todays_data
    @visits_today          = todays_data.visits.to_s
    @revenue_today         = "#{CURRENCY}" + todays_data.transaction_revenue.to_s
    @checkouts_today       = todays_data.transactions.to_s
    @basket_size_today     = "#{CURRENCY}" + '%.2f' % todays_data.revenue_per_transaction.to_s
    @conversion_rate_today = '%.2f' % todays_data.conversion_rate.to_s + '%'
  end

  yesterdays_data = Metric.last(source: 'all', start_date: YESTERDAY, end_date: YESTERDAY)
  @visits_yesterday, @revenue_yesterday, @checkouts_yesterday, @basket_size_yesterday, @conversion_rate_yesterday = 0, 0, 0, 0, 0
  if yesterdays_data
    @visits_yesterday          = yesterdays_data.visits.to_s
    @revenue_yesterday         = "#{CURRENCY}" + yesterdays_data.transaction_revenue.to_s
    @checkouts_yesterday       = yesterdays_data.transactions.to_s
    @basket_size_yesterday     = "#{CURRENCY}" + '%.2f' % yesterdays_data.revenue_per_transaction.to_s
    @conversion_rate_yesterday = '%.2f' % yesterdays_data.conversion_rate.to_s + '%'
  end

  sdlw_data = Metric.last(source: 'all', start_date: SDLW, end_date: SDLW)
  @visits_sdlw, @revenue_sdlw, @checkouts_sdlw, @basket_size_sdlw, @conversion_rate_sdlw = 0, 0, 0, 0, 0
  if sdlw_data
    @visits_sdlw           = sdlw_data.visits.to_s
    @revenue_sdlw          = "#{CURRENCY}" + sdlw_data.transaction_revenue.to_s
    @checkouts_sdlw        = sdlw_data.transactions.to_s
    @basket_size_sdlw      = "#{CURRENCY}" + '%.2f' % sdlw_data.revenue_per_transaction.to_s
    @conversion_rate_sdlw  = '%.2f' % sdlw_data.conversion_rate.to_s + '%'
  end

  erb :'index'
end

#The data for today is updated every 10 minutes.
scheduler.every '10m' do
  puts 'Retrieving GA Data'
  all_metrics(TODAY, TODAY)
  visits_by_source(TODAY, TODAY)
end

#When you first fire up the app, you'll need to collect the historical data.
get '/refresh' do
  #Refresh the data for the graph. Visits by source for the last 8 days.
  (SDLW...TODAY).each do |date|
    visits_by_source(date, date)
  end

  #Refresh the data for number blocks.
  all_metrics(TODAY, TODAY)
  all_metrics(YESTERDAY, YESTERDAY)
  all_metrics(SDLW, SDLW)

  redirect '/'
end