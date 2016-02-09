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

### Request a certificate

    rapid = Rapid.new("https://rapid-server/", load_key())
    client_request_id = rapid.request(anonymised_user_id)

    def load_key
      p12 = OpenSSL::PKCS12.new(File.binread("rapid.client.pfx"), "pfx_password")
      return p12.key
    end

Then send `client_request_id` to the client for collection.

### Determine who has authenticated

    def show
      anon_id = Rapid.authenticate_user(request.env["HTTP_SSL_CLIENT_CERT"])
      @user = Users.from_anonymous_id(anon_id)
      redirect_to @user
    end
    
## Apache Server Configuration

You need to tell Apache about the RapID CA certificate so it can trust the certificates issued by 
the RapID service.  You also need a set of URLs that will be be authenticated by the client certificate.
These have `SSLVerifyClient` set to `require`.  We have also found it necessary to set a `RequestHeader`
even though the official documentation does not mention this.

    <VirtualHost 10.1.101.67:443>
	
      # General SSL configuration: server cert, ciphers, etc.
      # ...
	  
      # this is where the Rapid root CA certificate is stored
      SSLCACertificateFile /home/bitnami/blog/ssl/trusted.ca.crt
	
      # At least one authenticated URL	
      <Location /logon>
        SSLVerifyClient require
        SSLOptions +ExportCertData
        RequestHeader set SSL_CLIENT_CERT "%{SSL_CLIENT_CERT}s"
      </Location>
    </VirtualHost>


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

