Dash
====

A simple dashboard for ecommerce companies using Google Analytics. Dash regularly polls your Google Analytics account and stores some of the most important metrics about a site's traffic. It is my first attempt at a Sinatra app. I built the first version of Dash in Rails for a client and they found the ability to see how their different traffic sources looked in a stacked area chart particularly helpful.

![](https://dl.dropbox.com/u/11299300/dash_v1.png)

## Installation

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

Then, to test it locally, run:

```ruby
bundle install
shotgun app.rb
```

