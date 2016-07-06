
# Yodlee Wrap


Yodlee Wrap is a ruby gem wrapping the new Yodlee REST API (2016). It is built on the roots of the Yodlee-icious gem, but works with the newly named endpoints and resource names.


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'yodlee_wrap'
```

 Then:

    $ bundle install

Or, outside Rails:

    $ gem install yodlee_wrap

## Usage

### Configuration

Like Yodleeicious, you can continue to use the app from within Rails or externally. Outside of rails (even in an irb session)

```ruby
require "yodlee_wrap"

config = {
  cobranded_username: your_username,
  cobranded_password: your_password,
  webhook_endpoint: your_webhook_endpoint
}

yodlee_api = YodleeWrap::YodleeApi.new(config)

```
When in a Rails app it can be more convenient to use a global default configuration. To use global defaults:

```ruby
#/<myproject>/config/initializers/yodleeicious.rb
require 'yodlee_wrap'

#setting default configurations for Yodleeicious
YodleeWrap::Config.base_url = ENV['YODLEE_BASE_URL']
YodleeWrap::Config.cobranded_username = ENV['YODLEE_COBRANDED_USERNAME']
YodleeWrap::Config.cobranded_password = ENV['YODLEE_COBRANDED_PASSWORD']
YodleeWrap::Config.webhook_endpoint = ENV['YODLEE_WEBHOOK_ENDPOINT']

#setting yodleeicious logger to use the Rails logger
YodleeWrap::Config.logger = Rails.logger
```
and wherever you want to use the api simply create a new one and it will pickup the global defaults.

```ruby
yodlee_api = YodleeWrap::YodleeApi.new
```
If for any reason you need to, you can pass a hash into the constructor and it will use any provided hash values over the defaults. Note this is done on each value not the entire hash.


## TODO: Documentation

For right now, check the source code for documentation. I'll document when there is more time.

For endpoints that are not currently included, you can call them directly on your yodlee_wrap object using

``` yodlee_api.user_execute_api(:http_method, endpoint)
```

## Contributing

1. Fork it ( https://github.com/liftforward/yodlee-icious/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
