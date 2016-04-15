require 'test_helper'
require 'rest-client'
require 'json'
require "base64"

class RapidTest < Minitest::Test

  def test_rapid_connects_to_rapid_server_at_url
    rapid = Rapid.new(load_key())
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
    rapid = Rapid.new(nil)
    rapid.host = "server/rapid"
    assert_equal "https://server/rapid/1.0/RequestCredential", rapid.rapid_request_url
  end

  def test_rapid_contructed_from_complete_url_uses_that_url
    rapid = Rapid.new nil
    rapid.host = "https://server/rapid"
    assert_equal "https://server/rapid/1.0/RequestCredential", rapid.rapid_request_url
  end

  def test_rapid_contructed_from_just_one_word_uses_that_as_host
    rapid = Rapid.new(nil)
    rapid.host = "server"
    assert_equal "https://server/1.0/RequestCredential", rapid.rapid_request_url
  end

  def test_rapid_contructed_from_host_and_path
    rapid = Rapid.new(nil)
    rapid.host = "server/rapid"
    assert_equal "https://server/rapid/1.0/RequestCredential", rapid.rapid_request_url
  end

  def test_rapid_contructed_from_https_scheme_and_host
    rapid = Rapid.new(nil)
    rapid.host = "https://server"
    assert_equal "https://server/1.0/RequestCredential", rapid.rapid_request_url
  end

  def test_rapid_contructed_from_https_scheme_host_and_path
    rapid = Rapid.new(nil)
    rapid.host = "https://server/rapid"
    assert_equal "https://server/rapid/1.0/RequestCredential", rapid.rapid_request_url
  end

  def test_rapid_contructed_from_https_scheme_path_and_host
    rapid = Rapid.new(nil)
    rapid.host = "https://server:443"
    assert_equal "https://server:443/1.0/RequestCredential", rapid.rapid_request_url
  end

  def test_rapid_contructed_from_https_customr_port
    rapid = Rapid.new(nil)
    rapid.host = "https://server:4443"
    assert_equal "https://server:4443/1.0/RequestCredential", rapid.rapid_request_url
  end

  def test_rapid_contructed_from_http_scheme_and_host_uses_https_in_url
    rapid = Rapid.new(nil)
    rapid.host = "http://server"
    assert_equal "https://server/1.0/RequestCredential", rapid.rapid_request_url
  end  


  def load_key
    p12 = OpenSSL::PKCS12.new(File.binread("Rapid_Shiraz_Live_Client.pfx"), "12")
    return p12
  end

end


class RapidAuthTest < Minitest::Test
  def test_that_cert_is_parsed
    cert = 
    "-----BEGIN CERTIFICATE----- 
    MIIGPjCCBSagAwIBAgITTwAAAL9YW/t8IzJ0EwAAAAAAvzANBgkqhkiG9w0BAQsF 
    ADBDMRUwEwYKCZImiZPyLGQBGRYFbG9jYWwxFTATBgoJkiaJk/IsZAEZFgVyYXBp 
    ZDETMBEGA1UEAxMKUkFQSUQtREMwMTAeFw0xNjAxMjAwNzQ3MzZaFw0xNzAxMTkw 
    NzQ3MzZaMBUxEzARBgNVBAMTCjEyMzQ1Njc4OTAwggEiMA0GCSqGSIb3DQEBAQUA 
    A4IBDwAwggEKAoIBAQDB7jeObW+jQPngnUh6+W8D3jvmF3O9gl61RIzqGzTAlaZI 
    znfkg7zjCvAY8UIiIuA0AgmkBXpZAfTupkpsbdfKBF74Si/Fa5bRPS/WJ0wqROqh 
    QaUBCMj03blcRVrFf1/H5dmnnAUpZ7XonB0hotPkj12PHNNpgoENVbuHNwN4BWvX 
    wn8EHBh91llQyDozMh4F2YkglHTYsbo7yX0h/OwysXr+5frvAG3K9QhBWiwFBGyG 
    bSK2SmfAV7iLe59EGYrJ9COyDpFdRqzDtmOYnibWGSC1agiQLJAdlIfUUWiZdOw6 
    AKBkEFkWaqggZf+fCUxLqRCeGTMZVPFKf50ZNgYzAgMBACGjggNXMIIDUzAdBgNV 
    HQ4EFgQUG733OXCZzLBjN5FftcFPolTagm8wHwYDVR0jBBgwFoAUjT6zoOzSTTvp 
    /TzrMkYG14K2w4MwgcsGA1UdHwSBwzCBwDCBvaCBuqCBt4aBtGxkYXA6Ly8vQ049 
    UkFQSUQtREMwMSxDTj1SQVBJRC1EQzAxLENOPUNEUCxDTj1QdWJsaWMlMjBLZXkl 
    MjBTZXJ2aWNlcyxDTj1TZXJ2aWNlcyxDTj1Db25maWd1cmF0aW9uLERDPXJhcGlk 
    LERDPWxvY2FsP2NlcnRpZmljYXRlUmV2b2NhdGlvbkxpc3Q/YmFzZT9vYmplY3RD 
    bGFzcz1jUkxEaXN0cmlidXRpb25Qb2ludDCCARoGCCsGAQUFBwEBBIIBDDCCAQgw 
    gakGCCsGAQUFBzAChoGcbGRhcDovLy9DTj1SQVBJRC1EQzAxLENOPUFJQSxDTj1Q 
    dWJsaWMlMjBLZXklMjBTZXJ2aWNlcyxDTj1TZXJ2aWNlcyxDTj1Db25maWd1cmF0 
    aW9uLERDPXJhcGlkLERDPWxvY2FsP2NBQ2VydGlmaWNhdGU/YmFzZT9vYmplY3RD 
    bGFzcz1jZXJ0aWZpY2F0aW9uQXV0aG9yaXR5MFoGCCsGAQUFBzABhk5odHRwOi8v 
    UkFQSUQtREMwMS5yYXBpZC5sb2NhbC9DZXJ0RW5yb2xsL1JBUElELURDMDEucmFw 
    aWQubG9jYWxfUkFQSUQtREMwMS5jcnQwDgYDVR0PAQH/BAQDAgWgMDwGCSsGAQQB 
    gjcVBwQvMC0GJSsGAQQBgjcVCNexIoTfpyeD/ZU0hO3sD4ecv3wGhemRQIXp8XcC 
    AWQCAQgwKQYDVR0lBCIwIAYKKwYBBAGCNxQCAgYIKwYBBQUHAwIGCCsGAQUFBwME 
    MDUGCSsGAQQBgjcVCgQoMCYwDAYKKwYBBAGCNxQCAjAKBggrBgEFBQcDAjAKBggr 
    BgEFBQcDBDBEBgkqhkiG9w0BCQ8ENzA1MA4GCCqGSIb3DQMCAgIAgDAOBggqhkiG 
    9w0DBAICAIAwBwYFKw4DAgcwCgYIKoZIhvcNAwcwLwYDVR0RBCgwJoYkODg0OGE2 
    OTMtYmRhZC00MDUzLWE5MGYtZGE4YjBhYzhkNGM0MA0GCSqGSIb3DQEBCwUAA4IB 
    AQBsL6ZKHaymg47E9i+iKr2ekE6mhULpYQMXRDM7HSD8khEF3JbciM4KrQCadcjB 
    XnSJbILduf4EvQnhT5MsJ7MKYJiqIq+txJoPu3ZU/73SNaIogU6E7D6BDq4K81Up 
    H9H44dCvHPgVw+WADhD4yoCjEJa/fiGnYpp0TrxxwHKv71ul6gFPp54Qpbq1kb4j 
    WKsRCK8qZ1+HMswu1AHXtwPL/DC3aslP165cv6HbHSIXcgseSBJ4XOrziqj0KhW0 
    wyKQ8RnWhZ/9h5UsVyMa8TLsEedo73u2nhedU9NIWnYzzkJ2oSRp9tntm7iPJnLf 
    dX2GgOPYoge87aL54vI9sPw5 
    -----END CERTIFICATE-----"
    
    request = OpenStruct.new(
      { "env" => OpenStruct.new({ "HTTP_SSL_CLIENT_CERT" => cert }) })
      
    auid = Rapid.authenticated_user(request)
    assert_equal "8848a693-bdad-4053-a90f-da8b0ac8d4c4", auid
  end
end