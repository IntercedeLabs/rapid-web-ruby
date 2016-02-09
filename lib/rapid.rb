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
   #    >> rapid = Rapid.new("https://rapid-server/", load_key())
   #    >> rapid.request(anonymised_user_id)
   #    => <GUID to pass to client for collecting the certificate>
   #
   #    def load_key
   #      p12 = OpenSSL::PKCS12.new(File.binread("rapid.client.pfx"), "pfx_password")
   #      return p12.key
   #    end


  attr_accessor :rapid_request_url
  attr_reader :rapid_client_key

  # A Rapid object talks to the RapID service found at host.  RapID uses JSON Web Tokens to
  # validate authenticity of messages, these JWTs are signed by rapid_client_key which must 
  # be an RSA 256 bit encryption key for the certificate configured on the RapID service.
  #
  # The host must be either a hostname, host and path, or full URL, all pointing to the RapID
  # top level.
  def initialize(host, rapid_client_key)
    raise ArgumentError, 'Missing Rapid host' unless host
    @rapid_request_url = buildRapidUrl(host)
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
        return sendRequest(jwt)["Identifier"]
    rescue RestClient::Exception => e
        begin
            response = JSON.parse(e.response)
            raise RuntimeError, "Requesting credential failed with server message '#{response["Message"]}'"
        rescue JSON::ParserError
            raise RuntimeError, "Requesting credential failed with HTTP status '#{e.response.code}'"
        end
    rescue SocketError => e
        raise RuntimeError, "Problem connecting to '#{@rapid_request_url}': #{e}"
    end
  end


  # Extracts the anonymous user ID from the SSL client certificate that was used to authenticate
  # to the website.
  #
  # Configure at least one URL to be protected by client SSL.  In Apache this is done like so:
  # <VirtualHost server-name:443>
  #   ...
  #   <Location /authenticated/url>
  #     SSLVerifyClient require
  #     SSLOptions +ExportCertData   # apparently this line should be enough, but not for me
  #     SSLVerifyDepth 1
  #     RequestHeader set SSL_CLIENT_CERT "%{SSL_CLIENT_CERT}s"   # this is the line that worked
  #   </Location>
  # </VirtualHost>
  #
  # Then inside your ruby website you want to get the anonymous user ID, for example:
  # def index
  #   anon_user_id = Rapid.authenticate_user(request.env["HTTP_SSL_CLIENT_CERT"])
  #   ...
  # end
  def self.authenticated_user(ssl_client_certificate)
    cert = ssl_client_certificate.to_s.split.join
    cert = cert.sub! '-----BEGINCERTIFICATE-----', ''
    cert = cert.sub! '-----ENDCERTIFICATE-----', ''

    cert = Base64.decode64(cert)
    cert = OpenSSL::X509::Certificate.new(cert)
    cert = cert.extensions.find {|e| e.oid == "subjectAltName"}
    cert = cert.value.to_s
    cert.slice!('URI:')
    return cert
  end

  


  def buildRapidUrl(url)
    parsed = URI(url);
    raise ArgumentError, "Invalid RapID URL" if [parsed.host, parsed.path].all? { |v| v.nil? || v.empty? }

    hostPath = ""
    hostPath = parsed.host if !parsed.host.nil? && !parsed.host.empty?
    hostPath = hostPath += ":#{parsed.port}" if !parsed.port.nil? && parsed.port && /:#{parsed.port}/.match(url)
    hostPath = hostPath += "#{parsed.path}" if !parsed.path.nil? && !parsed.path.empty?

    return "https://#{hostPath}/1.1/RequestCredential";        
  end


  def signRequest(payload)
    return JWT.encode(payload, rapid_client_key, 'RS256')
  end

  def sendRequest(request)
    response = RestClient.post(@rapid_request_url, request, :content_type => :json, :accept => :json)
    return JSON.parse(response)
  end
end
