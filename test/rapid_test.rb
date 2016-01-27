require 'test_helper'

class RapidTest < Minitest::Test

  def test_rapid_connects_to_rapid_server_at_url
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

  def test_rapid_contructed_from_complete_url_uses_that_url
    rapid = Rapid.new "https://server/rapid", nil
    assert_equal "https://server/rapid/1.1/RequestCredential", rapid.rapid_request_url
  end

  def test_rapid_contructed_from_just_one_word_uses_that_as_host
    rapid = Rapid.new("server", nil)
    assert_equal "https://server/1.1/RequestCredential", rapid.rapid_request_url
  end

  def test_rapid_contructed_from_host_and_path
    rapid = Rapid.new("server/rapid", nil)
    assert_equal "https://server/rapid/1.1/RequestCredential", rapid.rapid_request_url
  end

  def test_rapid_contructed_from_https_scheme_and_host
    rapid = Rapid.new("https://server", nil)
    assert_equal "https://server/1.1/RequestCredential", rapid.rapid_request_url
  end

  def test_rapid_contructed_from_https_scheme_host_and_path
    rapid = Rapid.new("https://server/rapid", nil)
    assert_equal "https://server/rapid/1.1/RequestCredential", rapid.rapid_request_url
  end

  def test_rapid_contructed_from_https_scheme_path_and_host
    rapid = Rapid.new("https://server:443", nil)
    assert_equal "https://server:443/1.1/RequestCredential", rapid.rapid_request_url
  end

  def test_rapid_contructed_from_https_customr_port
    rapid = Rapid.new("https://server:4443", nil)
    assert_equal "https://server:4443/1.1/RequestCredential", rapid.rapid_request_url
  end

  def test_rapid_contructed_from_http_scheme_and_host_uses_https_in_url
    rapid = Rapid.new("http://server", nil)
    assert_equal "https://server/1.1/RequestCredential", rapid.rapid_request_url
  end  


  def load_key
    p12 = OpenSSL::PKCS12.new(File.binread("rapid.testing.rp.pfx"), "rapidtests")
    p12.key
  end

end
