Dash
====

Dash is a simple dashboard for ecommerce companies using Google Analytics. Dash regularly polls your Google Analytics account and stores some of the most important metrics about a site's traffic. 

You can see Dash working here: http://dashtest.herokuapp.com

![](https://dl.dropbox.com/u/11299300/dash_v1.png)

This is my first attempt at creating an app using Sinatra. Originally, I built a dashboard for a client using rails. They found the ability to see how their different traffic sources looked in a stacked area chart particularly helpful.

## Installation

Dash works best if you have ecommerce tracking enabled on Google Analytics. You can read more about ecommerce tracking here: https://developers.google.com/analytics/devguides/collection/gajs/gaTrackingEcommerce

To get Dash up-and-running, you'll want to change a few things at the top of the app.rb file:

```ruby
#Set the access credentials for your GA account and the ID of the site. #Todo — don't check in password!
username = 'admin@domain.com'
password = '*****'
profile_id = 'UA-0000000-0'

#Set the name of the brand. This is used to split out search traffic.
BRAND_NAME = 'smith'

#Set the currency of the store
CURRENCY = '&pound;'
```

Then, to test it locally, run the following commands from the app's directory using terminal:

```
bundle install
shotgun app.rb
```

Then, to get the historical data, you can call the refresh method from your browser:

`http://localhost:4567/refresh`
