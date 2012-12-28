Dash
====

Dash is a simple dashboard for ecommerce companies using Google Analytics. Dash regularly polls your Google Analytics account and stores some of the most important metrics about a site's traffic. Originally, I built a dashboard for a client using rails and they found the ability to see how their different traffic sources looked in a stacked area chart particularly helpful. I decided afterwards that this would be a good app to try and build using Sinatra. 

![](https://dl.dropbox.com/u/11299300/dash_v1.png)

## Installation

Dash works best if you have ecommerce tracking enabled on Google Analytics. You can read more about ecommerce tracking here: 

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

