require "rapid/version"
require 'jwt'
require 'RestClient'
require 'json'
require 'uri'

class Rapid

  attr_accessor :rapid_request_url
  attr_reader :rapid_client_key

  def initialize(host, rapid_client_key)
    raise ArgumentError, 'Missing Rapid host' unless host
    @rapid_request_url = buildRapidUrl(host)
    @rapid_client_key = rapid_client_key
  end

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
