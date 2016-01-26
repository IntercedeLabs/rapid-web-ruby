require 'test_helper'

class RapidTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Rapid::VERSION
  end

  def test_that_it_throws_if_constructed_from_null_url
    refute_nil ::Rapid.new
  end
end
