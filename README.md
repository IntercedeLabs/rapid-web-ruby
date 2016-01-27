# RapID Web for Ruby

Inform the Rapid server to expect a device to collect a credential.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rapid', :path => '<path_to_gem_on_filesystem>'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rapid -=path=<path_to_gem_on_filesystem>

## Usage

    rapid = Rapid.new("https://rapid-server/", load_key())
    client_request_id = rapid.request(anonymised_user_id)

    def load_key
      p12 = OpenSSL::PKCS12.new(File.binread("rapid.client.pfx"), "pfx_password")
      return p12.key
    end

Then send `client_request_id` to the client for collection.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

