require 'rapid'
require 'minitest/autorun'

class RapidTest < Minitest::Test

  def test_rapid_connects_to_rapid_server_at_url
    rapid = Rapid.new("rapid-demo.intercedelabs.com/rapid", load_key())
    id = rapid.request("RapidSecurity.Test.User")
    print "\n\nRequest ID: #{id}\n"
  end

  def load_key
    p12 = OpenSSL::PKCS12.new(File.binread("rapid.testing.rp.pfx"), "rapidtests")
    p12.key
  end

end
