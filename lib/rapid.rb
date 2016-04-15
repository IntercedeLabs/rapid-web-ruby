# This file is part of the MyID RapID package.

require "rapid/version"
require 'jwt'
require 'rest-client'
require 'json'
require 'uri'

class Rapid
   #  Inform the Rapid server to expect a device to collect a credential.
   #
   #  Example:
   #    >> rapid = Rapid.new(load_key())
   #    >> rapid.request(anonymised_user_id)
   #    => <GUID to pass to client for collecting the certificate>
   #
   #    def load_key
   #      p12 = OpenSSL::PKCS12.new(File.binread("rapid.client.pfx"), "pfx_password")
   #      return p12
   #    end


  attr_accessor :rapid_request_url
  attr_reader :rapid_client_key


  # A Rapid object talks to the RapID Auth service.  RapID uses TLS to validate 
  # authenticity of messages and must be provided with an authentication certificate.
  # Service authentication certificates are downloaded from the Customer Portal. 
  def initialize(rapid_client_key)
    @rapid_request_url = buildRapidUrl("request.rapidauth.com/rapid")
    @rapid_client_key = rapid_client_key
  end

  # The subjectName is an anonymised identifier mapped by your website to a user&device.  It 
  # will be put verbatim into the Common Name of the certificate issued to the device.
  #
  # When the device later connects to your website it will present the client certificate via
  # mutual TLS. 
  def request(subjectName)
    payload = { :SubjectName => subjectName }
    jwt = signRequest payload

    begin
        return sendRequest(jwt)["requestId"]
    rescue RestClient::Exception => e
        begin
            response = JSON.parse(e.response)
            raise RuntimeError, "Requesting credential failed with server message '#{response["Message"]}'"
        rescue JSON::ParserError
            raise RuntimeError, "Requesting credential failed with HTTP status '#{e.response.code}' : #{e.response}"
        end
    rescue SocketError => e
        raise RuntimeError, "Problem connecting to '#{@rapid_request_url}': #{e}"
    end
  end


  # Extracts the anonymous user ID from the SSL client certificate that was used to 
  # authenticate to the website.
  #
  #
  # Inside your ruby website you want to get the anonymous user ID, for example:
  # def index
  #   anon_user_id = Rapid.authenticate_user(request)
  #   ...
  # end
  #
  #
  # == Development Environment ==
  #
  # To enable easy development you can use the RapID SDK without SSL configured in Rails 
  # development mode.  In this scenario authenticated_user will return the anonymised 
  # user ID that is passed in the JSON payload.  By default this is expected to be in a 
  # JSON attribute 'rapid_dev_anon_id'.
  #
  #
  # Development mode is configured in different ways depending on your server choice:
  #  * Puma 
  #    Edit the {{environment}} in {{config/puma.rb}} to be {{development}}
  #
  #  * Apache
  #    In your virtual host .conf add {{RailsEnv development}} to the VirtualHost block.
  #
  #
  # == Production Environment ==
  #
  # For production, configure at least one URL to be protected by client SSL.  Also make 
  # sure the environment is set to 'production' (see above).  
  #
  # In Apache this is done client SSL is configured  like so:
  # <VirtualHost server-name:443>
  #   ...
  #   <Location /authenticated/url>
  #     SSLVerifyClient require
  #     SSLOptions +ExportCertData
  #     SSLVerifyDepth 1
  #     RequestHeader set SSL_CLIENT_CERT "%{SSL_CLIENT_CERT}s"
  #   </Location>
  # </VirtualHost>
  #
  def self.authenticated_user(request, dev_json_name = 'rapid_dev_anon_id')
    cert = request.env["HTTP_SSL_CLIENT_CERT"]
    return anon_user_id_from_cert(cert) if !(cert.nil? || cert.empty?) && cert != "(null)"
    raise RuntimeError, "No cerficiate found in HTTP_SSL_CLIENT_CERT" if Rails.env.production?

    return request.params[dev_json_name] unless request.params[dev_json_name].nil? if Rails.env.development?
    raise RuntimeError, "In development mode, no certificate or #{dev_json_name} found"
  end
 




















  # The host must be either a hostname, host and path, or full URL, all pointing to the RapID
  # top level.
  def host=(host)
    raise ArgumentError, 'Missing Rapid host' unless host
    @rapid_request_url = buildRapidUrl(host)
  end


  def self.anon_user_id_from_cert(ssl_client_certificate)
    cert = ssl_client_certificate.to_s.split.join
    cert = cert.sub! '-----BEGINCERTIFICATE-----', ''
    cert = cert.sub! '-----ENDCERTIFICATE-----', ''

    cert = Base64.decode64(cert)
    cert = OpenSSL::X509::Certificate.new(cert)
    san = cert.extensions.find {|e| e.oid == "subjectAltName"}
    san = san.value.to_s
    san.slice!('URI:')
    return san
  end




  def buildRapidUrl(url)
    parsed = URI(url);
    raise ArgumentError, "Invalid RapID URL" if [parsed.host, parsed.path].all? { |v| v.nil? || v.empty? }

    hostPath = ""
    hostPath = parsed.host if !parsed.host.nil? && !parsed.host.empty?
    hostPath = hostPath += ":#{parsed.port}" if !parsed.port.nil? && parsed.port && /:#{parsed.port}/.match(url)
    hostPath = hostPath += "#{parsed.path}" if !parsed.path.nil? && !parsed.path.empty?

    return "https://#{hostPath}/1.0/RequestCredential";        
  end


  def signRequest(payload)
    return payload.to_json
  end

  def sendRequest(request)
    print "\nRapID client certificate details:"
    print "\nIssued To: #{rapid_client_key.certificate.subject}"
    print "\nIssued By: #{rapid_client_key.certificate.issuer}"
    print "\nSerial No: #{rapid_client_key.certificate.serial}"
    
    response = RestClient::Resource.new(
      @rapid_request_url,
      :ssl_client_cert  =>  rapid_client_key.certificate,
      :ssl_client_key   =>  rapid_client_key.key,
      :content_type => :json,
      :accept => :json
    ).post(request)

    return JSON.parse(response)
  end
end
