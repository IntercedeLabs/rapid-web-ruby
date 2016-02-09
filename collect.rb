require 'rest-client'
require 'json'
require "base64"



def generate_key()
  OpenSSL::PKey::RSA.new 2048
end


def create_csr(key, requestId)
  request = OpenSSL::X509::Request.new
  request.version = 0 
  request.subject = OpenSSL::X509::Name.new([])  
  request.public_key = key.public_key
  request.sign(key, OpenSSL::Digest::SHA1.new)
end 


def simulate_request
  begin
    request = { 'SubjectName' => "sam jones" }.to_json
    response = RestClient.post("https://rapid-demo.intercedelabs.com/Bank/Register", request, :content_type => :json, :accept => :json)
    id = JSON.parse(response)["Identifier"]
  rescue => e
    print "error: #{e}\n"
    raise
  end

  # or if you haven't implemented your "register" URL yet, use the server-side Rapid client...
  # rapid = Rapid.new("rapid-demo.intercedelabs.com/rapid", load_key())
  # id = rapid.request("RapidSecurity.Test.User")

#    print "requestID: #{id}\n\n"

  return id
end


def simulate_collect(id)
  key = generate_key

  # not quite standard PEM format
  certReq = create_csr( key, id )
  certReq = certReq.to_s.split.join
  certReq = certReq.sub! '-----BEGINCERTIFICATEREQUEST-----', ''
  certReq = certReq.sub! '-----ENDCERTIFICATEREQUEST-----', ''

  # Rapid internal data structure
  collect = { 
    :Identifier => id,
    :Device => {
      :SerialNumber => "not_important",
      :DeviceTypeName => "not_important"
    },
    :Certificate => {
      :ContainerName => "RapidContainer",
      :PKCS10 => certReq
    }
  }.to_json

#    print "#{collect}\n"

  certData = RestClient.post("https://rapid-demo.intercedelabs.com/rapid/1.0/CollectCredential", 
              collect, 
              :content_type => :json, 
              :accept => :json)
#    print "Response: #{certData}\n"
  certData = JSON.parse(certData)["Certificate"]

  bytes = Base64.decode64(certData)
  cert = OpenSSL::X509::Certificate.new bytes
  print "Certificate sn: #{cert.serial}\n"
  print "#{cert}\n"
  print "#{key}\n"

  return cert, key
end


def simulate
  requestId = simulate_request
  certificate, key = simulate_collect(requestId)

  response = RestClient::Resource.new('https://rapid-demo.intercedelabs.com/BankSecure/GetAccountDetails',
                :ssl_client_cert => certificate,
                :ssl_client_key => key,
                :accept => :json)

  print response.get
end


simulate