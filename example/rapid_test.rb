require 'rapid'
require 'minitest/autorun'

class RapidTest < Minitest::Test

  def test_rapid_connects_to_rapid_server_at_url
    rapid = Rapid.new(load_p12())
    id = rapid.request("RapidSecurity.Test.User")
    print "\n\nRequest ID: #{id}\n"
  end

  def load_p12
    p12 = OpenSSL::PKCS12.new(File.binread("<path to your pfx>"), "<pfx password>")
    p12
  end

end
