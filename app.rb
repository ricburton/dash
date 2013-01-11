require 'rubygems'
require 'sinatra/base'
require 'sinatra/config_file'
require 'garb'
require 'data_mapper'
require 'rufus/scheduler'

module Dash
  #Set the name of the brand. This is used to split out search traffic.
  BRAND_NAME = 'smith'

  #Set the currency of the store
  CURRENCY = '&pound;'

  #TODO - Constants for the dates?
  TODAY     = Date.today
  YESTERDAY = TODAY - 1
  SDLW      = TODAY - 7

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

  class All
    extend Garb::Model
    metrics :visits, :transaction_revenue, :transactions, :revenue_per_transaction
  end

  class Visits
    extend Garb::Model
    metrics :visits
  end

  class GraphData
    def initialize(date_range)
      get_data(date_range)
    end

    def visits(source)
      [].tap do |v|
        (SDLW..TODAY).each do |date|
          check = Metric.last(start_date: date, end_date: date, source: source)
          visits = check.nil? ? 0 : check.visits
          v << visits
        end
      end
    end

    protected

    def get_data(date_range)
      date_range.each do |date|
        %w{branded nonbranded unknown affiliate social referral paid direct email}.each do |type|
          self.class.send :attr_accessor, type
          instance_variable_set "@#{type}", visits(type)
        end
      end
    end
  end

  class App < Sinatra::Base
    configure :development do
      require 'sinatra/reloader'
      register Sinatra::Reloader
    end

    configure do
      #Load up access details for Google Analytics
      register Sinatra::ConfigFile
      config_file 'config.yml'
      set :environment, :development

      #Create a session with GA.
      Garb::Session.login(settings.username, settings.password)
      set :profile, Garb::Management::Profile.all.detect {|p| p.web_property_id == profile_id}

      #Create the database.
      DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/development.db")
      DataMapper.finalize.auto_upgrade!

      #Start the scheduler for the regular downloading of GA data.
      set :scheduler, Rufus::Scheduler.start_new
      settings.scheduler.every '10m' do
        puts 'Retrieving GA Data'
        all_metrics(TODAY, TODAY)
        visits_by_source(TODAY, TODAY)
      end
    end

    get '/' do
      #Data for the stacked area chart.
      @branded, @nonbranded, @unknown, @affiliate, @social, @referral, @paid, @direct, @email = [], [], [], [], [], [], [], [], []

      #Get the last 7 days of data.
      @graph_data = GraphData.new(SDLW..TODAY)

      #Days for the Y axis
      @days = (SDLW..TODAY).map{|date| date.strftime("%a").to_s}

      #Data for the small data panels.
      @today     = keymetrics(TODAY)
      @yesterday = keymetrics(YESTERDAY)
      @sdlw      = keymetrics(SDLW)

      erb :index
    end

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

    helpers do
      def keymetrics(date)
        data = Metric.last(source: 'all', start_date: date, end_date: date)
        return {
          visits:           data.visits.to_s,
          revenue:          CURRENCY + data.transaction_revenue.to_s,
          checkouts:        data.transactions.to_s,
          basket_size:      CURRENCY + '%.2f' % data.revenue_per_transaction.to_s,
          conversion_rate:  '%.2f' % data.conversion_rate.to_s + '%'
        }
      end

      def all_metrics(start_date, end_date)
        d = settings.profile.all(start_date: start_date, end_date: end_date).first
        if d
          data = Metric.first_or_create(source: 'all',
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
      end

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
          d = settings.profile.visits(start_date: start_date, end_date: end_date, filters: filter).first

          # Find the last result using DataMapper
          if d
            #Save the data.
            data = Metric.first_or_create(start_date: start_date, end_date: end_date, source: source).update(visits: d.visits.to_f)
          else
            #check for older data
            old_data = Metric.first(start_date: start_date, end_date: end_date, source: source)
            if old_data.nil?
              #if the data is nil, create a record for 0
              Metric.new(start_date: start_date, end_date: end_date, source: source, visits: 0)
            else
              #otherwise, just save the old data
              old_data.save
            end
          end
        end
      end
    end
  end
end