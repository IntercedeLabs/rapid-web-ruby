require "rapid/version"
require 'jwt'
require 'RestClient'
require 'json'

class Rapid

  attr_accessor :rapid_request_url
  attr_reader :rapid_client_key

  def initialize(host, rapid_client_key)
    raise ArgumentError, 'Missing Rapid host' unless host
    @rapid_request_url = "https://#{host}/1.1/RequestCredential"
    @rapid_client_key = rapid_client_key
  end

  def request(subjectName)
    payload = { :SubjectName => subjectName }
    jwt = signRequest payload

    begin
        response = sendRequest jwt
        return response["Identifier"]
    rescue RestClient::Exception => e
        begin
            response = JSON.parse(e.response)
            raise RuntimeError, "Requesting credential failed with server message '#{response["Message"]}'"
        rescue JSON::ParserError
            raise RuntimeError, "Requesting credential failed with HTTP status '#{e.response.code}'"
        end
    end
  end

  def signRequest(payload)
    return JWT.encode payload, rapid_client_key, 'RS256'
  end

  def sendRequest(request)
    response = RestClient.post @rapid_request_url, request, :content_type => :json, :accept => :json
    return JSON.parse(response)
  end
end
