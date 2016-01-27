require 'test_helper'

class RapidTest < Minitest::Test

  def test_rapid_connectrs_to_rapid_server_at_url
    rapid = Rapid.new("rapid-demo.intercedelabs.com/rapid", load_key())
    id = rapid.request("RapidSecurity.Test.User")
    print "\n\nRequest ID: #{id}\n"
  end


  def test_that_it_has_a_version_number
    refute_nil ::Rapid::VERSION
  end

  def test_that_it_throws_if_constructed_from_nil_url
    assert_raises ArgumentError do 
        ::Rapid.new(nil, nil)
    end 
  end

  def test_that_rapid_pads_host_and_path_with_scheme_and_version
    server = Rapid.new("server/rapid", nil)
    assert_equal "https://server/rapid/1.1/RequestCredential", server.rapid_request_url
  end

  def load_key
    p12 = OpenSSL::PKCS12.new(File.binread("rapid.testing.rp.pfx"), "rapidtests")
    p12.key
  end

end
