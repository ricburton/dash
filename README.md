Dash
====

Dash is a simple dashboard for ecommerce companies using Google Analytics. Dash regularly polls your Google Analytics account and stores some of the most important metrics about a site's traffic.

You can see Dash working here: http://dashtest.herokuapp.com

![](http://f.cl.ly/items/3R2Z0T2q241H071w3b2k/dash_v1.png)

This is my first attempt at creating an app using Sinatra. Originally, I built a dashboard for a client using rails. They found the ability to see how their different traffic sources looked in a stacked area chart particularly helpful.

## Installation

Dash works best if you have ecommerce tracking enabled on Google Analytics. You can read more about ecommerce tracking here: https://developers.google.com/analytics/devguides/collection/gajs/gaTrackingEcommerce

To get Dash up-and-running, you'll want to create a config.yml file in the main directory with the following:

```ruby
username:   admin@domain.com
password:   *****
profile_id: UA-0000000-0
```

Then, at the top of app.rb, you'll want to modify the brand name of the site you're working on and the currency.

```ruby
#Set the name of the brand. This is used to split out search traffic.
BRAND_NAME = 'smith'

#Set the currency of the store
CURRENCY = '&pound;'
```

Then, to test it locally, run the following commands from the app's directory using terminal:

```
bundle install
shotgun config.ru
```

Then, to get the historical data, you can call the refresh method from your browser:

`http://localhost:9393/refresh`
